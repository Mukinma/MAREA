"""Generate the A4 edition from the Markdown and editable DOT sources."""
import json
import re
import subprocess
from functools import partial
from html import escape
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, CondPageBreak, Flowable, Frame, KeepTogether, LongTable,
    PageBreak, PageTemplate, Paragraph, Spacer, TableStyle, XPreformatted,
)
from reportlab.platypus.tableofcontents import TableOfContents

EDITION = Path(__file__).resolve().parent
MANUAL = EDITION.parent
REPO = MANUAL.parent.parent
PAGE_W, PAGE_H = A4
LEFT = RIGHT = 48
WIDTH = PAGE_W - LEFT - RIGHT
NAVY = colors.HexColor('#14263D')
BLUE = colors.HexColor('#2563EB')
SLATE = colors.HexColor('#475569')
GRAY = colors.HexColor('#64748B')
PALE = colors.HexColor('#F3F5F7')
RULE = colors.HexColor('#DCE3EB')
BODY = colors.HexColor('#25374E')


def register_fonts():
    for variant in ('Regular', 'Bold', 'ExtraBold'):
        pdfmetrics.registerFont(TTFont(f'Nunito{variant}', REPO / 'assets' / 'fonts' / f'NunitoSans-{variant}.ttf'))
    pdfmetrics.registerFontFamily('NunitoRegular', normal='NunitoRegular', bold='NunitoBold',
                                  italic='NunitoRegular', boldItalic='NunitoBold')


def style(name, **overrides):
    values = dict(fontName='NunitoRegular', fontSize=10.5, leading=14.6,
                  textColor=BODY, spaceAfter=9, allowWidows=0, allowOrphans=0)
    values.update(overrides)
    return ParagraphStyle(name, **values)


STYLES = {
    'body': style('body'),
    'chapter': style('chapter', fontName='NunitoExtraBold', fontSize=23, leading=27,
                     textColor=NAVY, spaceBefore=16, spaceAfter=11, keepWithNext=True),
    'sub': style('sub', fontName='NunitoBold', fontSize=14, leading=18, textColor=NAVY,
                 spaceBefore=10, spaceAfter=5, keepWithNext=True),
    'bullet': style('bullet', leftIndent=14, bulletIndent=2, spaceAfter=5),
    'caption': style('caption', fontSize=9, leading=12.6, textColor=SLATE, spaceAfter=11),
    'th': style('th', fontName='NunitoBold', fontSize=9.4, leading=12.1,
                textColor=colors.white, spaceAfter=0),
    'td': style('td', fontSize=9.15, leading=12.25, spaceAfter=0),
    'code': style('code', fontName='Courier', fontSize=8.1, leading=11.35,
                  textColor=NAVY, backColor=PALE, borderPadding=(8, 10, 8, 10),
                  spaceBefore=5, spaceAfter=12),
    'index': style('index', fontSize=12, leading=22, spaceAfter=0, textColor=NAVY),
}


def inline(tokens):
    parts = []
    for token in tokens:
        kind = token['type']
        value = escape(token.get('text', ''))
        if kind in ('text', 'escape'):
            parts.append(value)
        elif kind in ('strong', 'em'):
            tag = 'b' if kind == 'strong' else 'i'
            parts.append(f'<{tag}>{inline(token["tokens"])}</{tag}>')
        elif kind == 'codespan':
            parts.append(f'<font name="Courier" size="8.5" color="#233D66">{value}</font>')
        elif kind == 'br':
            parts.append('<br/>')
        elif kind == 'link':
            href = token['href']
            label = inline(token['tokens'])
            if href.startswith(('#cap-', 'https://')):
                parts.append(f'<link href="{escape(href, quote=True)}" color="#2563EB">{label}</link>')
            else:
                parts.append(f'<font color="#254B81">{label}</font>')
        else:
            raise ValueError(f'Unsupported inline Markdown token: {kind}')
    return ''.join(parts)


def make_table(token):
    columns = len(token['header'])
    first = token['header'][0]['text']
    weights = {
        'Edge Function': (.19, .37, .44),
        'Hallazgo': (.26, .25, .49),
        'Síntoma': (.23, .47, .30),
        'Define': (.37, .63),
    }.get(first, {2: (.31, .69), 3: (.21, .55, .24), 4: (.19, .24, .26, .31)}[columns])
    header = [Paragraph(inline(cell['tokens']), STYLES['th']) for cell in token['header']]
    rows = [[Paragraph(inline(cell['tokens']), STYLES['td']) for cell in row] for row in token['rows']]
    table = LongTable([header, *rows], [WIDTH * part for part in weights], repeatRows=1,
                      hAlign='LEFT', spaceBefore=4, spaceAfter=7)
    table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('BACKGROUND', (0, 0), (-1, 0), NAVY),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, PALE]),
        ('LINEBELOW', (0, 1), (-1, -1), .35, RULE),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
    ]))
    return table


def code_block(token):
    def highlight(line):
        if token.get('lang') == 'text':
            return escape(line)
        pattern = r'("[^"\n]*"|\b(?:flutter|node|cp|POST|HTTP/1\.1)\b|--[a-z][a-z-]*)'
        parts = re.split(pattern, line)
        return ''.join(escape(part) if index % 2 == 0 else
                       f'<font color="#185AB0">{escape(part)}</font>'
                       for index, part in enumerate(parts))

    lines = token['text'].splitlines()
    if any(pdfmetrics.stringWidth(line, 'Courier', 8.1) > WIDTH - 21 for line in lines):
        raise ValueError('A code line exceeds the print width. Wrap it in the Markdown source.')
    return KeepTogether([XPreformatted('\n'.join(highlight(line) for line in lines), STYLES['code'])])


class Graph(Flowable):
    """Draw the vector operations emitted by Graphviz's xdot JSON renderer."""

    def __init__(self, graph):
        super().__init__()
        self.graph = graph
        self.x0, self.y0, self.x1, self.y1 = map(float, graph['bb'].split(','))
        self.scale = min(1.0, (WIDTH - 16) / (self.x1 - self.x0), 335 / (self.y1 - self.y0))
        self.width = WIDTH
        self.height = (self.y1 - self.y0) * self.scale + 16
        self.spaceBefore = 5
        self.spaceAfter = 4

    def draw(self):
        c = self.canv
        c.setFillColor(colors.HexColor('#FAFCFF'))
        c.setStrokeColor(RULE)
        c.roundRect(.5, .5, self.width - 1, self.height - 1, 5, stroke=1, fill=1)
        c.saveState()
        c.translate((self.width - (self.x1 - self.x0) * self.scale) / 2, 8)
        c.scale(self.scale, self.scale)
        c.translate(-self.x0, -self.y0)
        nodes = self.graph.get('objects', [])
        edges = self.graph.get('edges', [])
        clusters = [node for node in nodes if 'nodes' in node]
        for item in [*clusters, *edges, *(node for node in nodes if 'nodes' not in node)]:
            for key, operations in item.items():
                if key.endswith('draw_'):
                    self.draw_operations(operations)
        c.restoreState()

    def draw_operations(self, operations):
        c = self.canv
        c.saveState()
        c.setStrokeColor(colors.black)
        c.setFillColor(colors.black)
        c.setLineWidth(1)
        font = ('Helvetica', 11)
        pen = colors.black
        transparent = False
        for item in operations:
            op = item['op']
            if op == 'c':
                pen = colors.toColor(item['color'])
                c.setStrokeColor(pen)
            elif op == 'C':
                fill = item['color']
                transparent = fill == 'transparent' or (len(fill) == 9 and fill.endswith('00'))
                if not transparent:
                    c.setFillColor(colors.toColor(fill))
            elif op == 'F':
                font = ('Helvetica', item['size'])
            elif op == 'S':
                if item['style'] == 'solid':
                    c.setDash()
                elif item['style'] == 'dashed':
                    c.setDash(4, 3)
                elif item['style'] == 'dotted':
                    c.setDash(1, 3)
                elif item['style'].startswith('setlinewidth('):
                    c.setLineWidth(float(item['style'].removeprefix('setlinewidth(').rstrip(')')))
                else:
                    raise ValueError(f'Unsupported graph style: {item["style"]}')
            elif op == 'T':
                x, y = item['pt']
                c.setFont(*font)
                draw = {'l': c.drawString, 'c': c.drawCentredString, 'r': c.drawRightString}
                # Graphviz supplies text color as the pen color before T.
                c.setFillColor(pen)
                draw[item['align']](x, y, item['text'])
            elif op in ('e', 'E'):
                x, y, rx, ry = item['rect']
                c.ellipse(x - rx, y - ry, x + rx, y + ry, stroke=1, fill=op == 'E' and not transparent)
            elif op in ('P', 'p', 'L', 'B', 'b'):
                points = item['points']
                path = c.beginPath()
                path.moveTo(*points[0])
                if op in ('B', 'b'):
                    for index in range(1, len(points), 3):
                        path.curveTo(*points[index], *points[index + 1], *points[index + 2])
                else:
                    for point in points[1:]:
                        path.lineTo(*point)
                if op in ('P', 'p'):
                    path.close()
                c.drawPath(path, stroke=1, fill=op in ('P', 'B') and not transparent)
            else:
                raise ValueError(f'Unsupported Graphviz draw operation: {op}')
        c.restoreState()


class Cover(Flowable):
    def __init__(self, title, metadata, subtitle):
        super().__init__()
        self.title, self.metadata, self.subtitle = title, metadata, subtitle
        self.width, self.height = WIDTH, 635

    def draw(self):
        c = self.canv
        c.setFillColor(NAVY)
        c.rect(0, 215, self.width, 394, stroke=0, fill=1)
        c.setFillColor(colors.HexColor('#8AB4FF'))
        c.rect(35, 541, 50, 3.2, stroke=0, fill=1)
        c.setFont('NunitoExtraBold', 24)
        c.setFillColor(colors.white)
        c.drawString(35, 499, self.metadata.split(' · ')[0])
        first, second = self.title.split(' de ', 1)
        c.setFont('NunitoExtraBold', 43)
        c.drawString(35, 424, first)
        c.drawString(35, 367, f'de {second}')
        c.setFillColor(colors.HexColor('#C8DAF0'))
        c.setFont('NunitoRegular', 12)
        c.drawString(35, 290, self.subtitle)
        c.setStrokeColor(RULE)
        c.line(0, 155, self.width, 155)
        c.setFillColor(NAVY)
        c.setFont('NunitoBold', 11)
        c.drawString(0, 127, ' · '.join(self.metadata.split(' · ')[1:]))


def page_furniture(canvas, doc, *, version):
    if doc.page == 1:
        return
    canvas.saveState()
    canvas.setStrokeColor(RULE)
    canvas.setLineWidth(.55)
    canvas.line(LEFT, PAGE_H - 45, PAGE_W - RIGHT, PAGE_H - 45)
    canvas.line(LEFT, 43, PAGE_W - RIGHT, 43)
    canvas.setFont('NunitoBold', 9)
    canvas.setFillColor(NAVY)
    canvas.drawString(LEFT, PAGE_H - 35, 'MAREA')
    canvas.setFillColor(GRAY)
    canvas.setFont('NunitoRegular', 9)
    canvas.drawRightString(PAGE_W - RIGHT, PAGE_H - 35, 'Manual Técnico de Software')
    canvas.drawString(LEFT, 28, version)
    canvas.drawRightString(PAGE_W - RIGHT, 28, f'{doc.page:02d}')
    canvas.restoreState()


class ManualDocument(BaseDocTemplate):
    def afterFlowable(self, flowable):
        destination = getattr(flowable, 'destination', None)
        if destination is None:
            return
        title = flowable.getPlainText()
        self.canv.bookmarkHorizontalAbsolute(destination, self.frame._y + flowable.height + 5)
        self.canv.addOutlineEntry(title, destination, 0, closed=False)
        self.notify('TOCEntry', (0, title, self.page, destination))


def content(tokens, graphs):
    index = TableOfContents()
    index.levelStyles = [STYLES['index']]
    index.dotsMinLevel = 0
    visible = [token for token in tokens if token['type'] != 'space']
    title, metadata, subtitle = [token['text'] for token in visible[:3]]
    metadata = metadata.replace('**', '')
    flows = [Cover(title, metadata, subtitle), PageBreak(),
             Paragraph('Índice', STYLES['chapter']), Spacer(1, 12), index, PageBreak()]
    destination = None
    inside_index = False
    figure = None
    for token in visible[3:]:
        kind = token['type']
        anchor = re.fullmatch(r'<a id="(cap-\d+)"></a>', token.get('text', '').strip())
        if anchor:
            destination = anchor.group(1)
        elif kind == 'html':
            marker = token['text'].strip()
            if marker == '<!-- indice -->':
                inside_index = True
            elif marker == '<!-- fin-indice -->':
                inside_index = False
            else:
                raise ValueError(f'Unsupported Markdown HTML: {marker}')
        elif inside_index:
            continue
        elif kind == 'heading':
            chapter = token['depth'] == 2
            heading = Paragraph(inline(token['tokens']), STYLES['chapter' if chapter else 'sub'])
            if chapter:
                if destination is None:
                    raise ValueError('Missing chapter anchor')
                heading.destination = destination
                minimum_space = 480 if destination == 'cap-15' else 104
                destination = None
                flows.append(CondPageBreak(minimum_space))
            flows.append(heading)
            if chapter:
                # Let a long opening table split after the chapter heading.
                flows.append(Spacer(1, 0))
        elif kind == 'paragraph':
            children = token['tokens']
            if len(children) == 1 and children[0]['type'] == 'image':
                figure = Graph(graphs[Path(children[0]['href']).name])
                continue
            text = inline(children)
            caption = token['text'].startswith(('*Tabla ', '*Figura '))
            para = Paragraph(text, STYLES['caption' if caption else 'body'])
            if figure is not None:
                if not token['text'].startswith('*Figura '):
                    raise ValueError('Figure without caption')
                flows.append(KeepTogether([figure, para]))
                figure = None
            else:
                flows.append(para)
        elif kind == 'table':
            flows.append(make_table(token))
        elif kind == 'code':
            flows.append(code_block(token))
        elif kind == 'list':
            for item in token['items']:
                bullet = '•'
                for child in item['tokens']:
                    if child['type'] not in ('text', 'paragraph'):
                        raise ValueError('Unsupported list nesting')
                    flows.append(Paragraph(inline(child['tokens']), STYLES['bullet'], bulletText=bullet))
                    bullet = None
        else:
            raise ValueError(f'Unsupported Markdown block: {kind}')
    return flows, metadata.split(' · ')[1]


def main():
    register_fonts()
    parsed = subprocess.run(['node', str(EDITION / 'preparar.cjs')], check=True, stdout=subprocess.PIPE)
    bundle = json.loads(parsed.stdout)
    flows, version = content(bundle['tokens'], bundle['graphs'])
    target = MANUAL / 'manual-tecnico.pdf'
    temporary = target.with_suffix('.pdf.tmp')
    frame = Frame(LEFT, 56, WIDTH, PAGE_H - 113, leftPadding=0, bottomPadding=0,
                  topPadding=0, rightPadding=0, id='main')
    document = ManualDocument(str(temporary), pagesize=A4, pageTemplates=[
        PageTemplate(id='manual', frames=[frame], onPage=partial(page_furniture, version=version)),
    ], title='MAREA · Manual Técnico de Software', subject='Arquitectura, instalación y operación de MAREA',
        author='', lang='es-MX', allowSplitting=True)
    try:
        document.multiBuild(flows)
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    main()
