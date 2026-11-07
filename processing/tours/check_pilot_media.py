"""Inspect a local GPano JPEG before a development pilot, without network I/O.

This checks the existing worker's input contract, not optical quality or whether
the image depicts a real place. No jobs, outputs, or backend objects are created.
"""
from __future__ import annotations

import argparse
import importlib.metadata
import importlib.util
import json
from pathlib import Path
import shutil
import warnings


PYTHON_DEPENDENCIES = (('Pillow', 'PIL'), ('numpy', 'numpy'), ('requests', 'requests'))
PHOTO_TOOLS = ('cpfind', 'cpclean', 'autooptimiser', 'pano_modify', 'nona', 'enblend')
MAX_INPUT_BYTES = 33_554_432
MESSAGES = {
    'missing_dependencies': 'Faltan dependencias Python del worker en este entorno. '
        'Consulta processing/tours/requirements.txt; esta herramienta no instala '
        'paquetes ni utiliza la red.',
    'dependency_import_failed': 'Una dependencia del worker no puede cargarse. '
        'Revisa el entorno Python y processing/tours/requirements.txt; no se '
        'ha utilizado la red ni instalado paquetes.',
    'file_not_found': 'No existe el archivo local seleccionado.',
    'not_a_regular_file': 'Selecciona un archivo local JPEG.',
    'file_unreadable': 'No pudimos leer el archivo local seleccionado.',
    'input_too_large': 'El JPEG supera el límite de entrada de 32 MiB.',
    'invalid_jpeg': 'El archivo no es un JPEG completo que pueda decodificarse.',
    'invalid_dimensions': 'Las dimensiones superan los límites del worker '
        '(64–24000 por eje y 120 millones de píxeles).',
    'image_orientation_not_normalized': 'Normaliza la orientación EXIF antes '
        'de importar, conservando una esfera y metadatos GPano válidos.',
    'gpano_full_sphere_required': 'Se requiere un JPEG con XMP GPano de esfera '
        'equirectangular completa, sin recorte y con dimensiones coincidentes. '
        'Una imagen 2:1 sin esos metadatos no basta.',
    'resource_limit': 'No hay memoria suficiente para decodificar este JPEG.',
}


class PilotMediaError(Exception):
    def __init__(self, code: str):
        self.code = code
        super().__init__(code)


def dependency_report() -> dict:
    """Report installed packages and executable presence; never execute tools."""
    dependencies = {}
    for distribution, module in PYTHON_DEPENDENCIES:
        try:
            available = importlib.util.find_spec(module) is not None
        except (ImportError, ValueError):
            available = False
        try:
            version = importlib.metadata.version(distribution) if available else None
        except importlib.metadata.PackageNotFoundError:
            version = None
        dependencies[distribution] = {'available': available, 'version': version}
    missing = [name for name, state in dependencies.items() if not state['available']]
    tools = {name: shutil.which(name) is not None for name in PHOTO_TOOLS}
    return {
        'python_dependencies': dependencies,
        'missing_python_dependencies': missing,
        'import_dependencies_available': not missing,
        'photo_tools': tools,
        'photo_tools_available': all(tools.values()),
        'note': 'Las herramientas de fotos no se necesitan para importar GPano. '
            'Su presencia no acredita una ejecución correcta del pipeline.',
    }


def validate_local_media(file: Path) -> dict:
    """Decode the JPEG and reuse the worker's GPano parser, without Backend."""
    try:
        size = file.stat().st_size
        if not file.is_file():
            raise PilotMediaError('not_a_regular_file')
    except FileNotFoundError:
        raise PilotMediaError('file_not_found') from None
    except OSError:
        raise PilotMediaError('file_unreadable') from None
    if size > MAX_INPUT_BYTES:
        raise PilotMediaError('input_too_large')

    # Keep these imports lazy so dependency diagnostics also work offline when
    # the worker's optional development environment has not been prepared.
    try:
        from PIL import Image
        from worker import TourError, validate_gpano
    except (ImportError, OSError):
        raise PilotMediaError('dependency_import_failed') from None

    try:
        with warnings.catch_warnings():
            warnings.simplefilter('error', Image.DecompressionBombWarning)
            with Image.open(file) as image:
                if image.format != 'JPEG':
                    raise PilotMediaError('invalid_jpeg')
                width, height = image.size
                if not (64 <= width <= 24000 and 64 <= height <= 24000
                        and width * height <= 120_000_000):
                    raise PilotMediaError('invalid_dimensions')
                if image.getexif().get(274, 1) != 1:
                    raise PilotMediaError('image_orientation_not_normalized')
                # Reading XMP/header dimensions alone does not detect a
                # truncated JPEG. Decode the pixels, without exporting them.
                image.load()
            width, height = validate_gpano(file)
    except TourError:
        raise PilotMediaError('gpano_full_sphere_required') from None
    except (Image.DecompressionBombError, Image.DecompressionBombWarning):
        raise PilotMediaError('invalid_dimensions') from None
    except (OSError, ValueError, SyntaxError, EOFError):
        raise PilotMediaError('invalid_jpeg') from None
    except MemoryError:
        raise PilotMediaError('resource_limit') from None
    return {
        'format': 'JPEG',
        'projection': 'equirectangular',
        'width': width,
        'height': height,
        'size_bytes': size,
        'xmp_validated': True,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--file', type=Path, help='JPEG GPano local; no se modifica.')
    mode.add_argument('--check-dependencies', action='store_true',
                      help='Comprueba paquetes y herramientas sin ejecutar ni instalar.')
    args = parser.parse_args(argv)
    dependencies = dependency_report()
    report = {'network_used': False}
    exit_code = 0
    if args.check_dependencies:
        report.update(status='dependencies_checked', **dependencies)
        if not dependencies['import_dependencies_available']:
            report.update(error_code='missing_dependencies',
                          message=MESSAGES['missing_dependencies'])
            exit_code = 2
    elif not dependencies['import_dependencies_available']:
        report.update(status='invalid', error_code='missing_dependencies',
                      missing_python_dependencies=dependencies['missing_python_dependencies'],
                      message=MESSAGES['missing_dependencies'])
        exit_code = 2
    else:
        try:
            media = validate_local_media(args.file)
            report.update(status='valid_gpano', media=media,
                          optical_quality='not_evaluated',
                          message='El JPEG cumple la validación de entrada GPano '
                          'del worker. La calidad óptica y el reconocimiento RA '
                          'requieren pruebas independientes.')
        except PilotMediaError as error:
            report.update(status='invalid', error_code=error.code,
                          message=MESSAGES[error.code])
            exit_code = 2
    # Do not echo filenames, absolute paths, exception text, XMP contents, or
    # embedded image metadata that is unrelated to the worker's input contract.
    print(json.dumps(report, ensure_ascii=True))
    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())
