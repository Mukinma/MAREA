import { SaxesParser } from "npm:saxes@6.0.0";

export const maxPanoramaBytes = 32 * 1024 * 1024;
const xmpId = "http://ns.adobe.com/xap/1.0/\0";
const exifId = "Exif\0\0";
const gpano = "http://ns.google.com/photos/1.0/panorama/";
const dimensions = [
  "FullPanoWidthPixels",
  "FullPanoHeightPixels",
  "CroppedAreaImageWidthPixels",
  "CroppedAreaImageHeightPixels",
  "CroppedAreaLeftPixels",
  "CroppedAreaTopPixels",
];

function invalid(): never {
  throw new Error("invalid_panorama");
}

function startsWith(data: Uint8Array, prefix: string) {
  return data.length >= prefix.length &&
    [...prefix].every((part, i) => data[i] === part.charCodeAt(0));
}

function validateProjection(xml: string, width: number, height: number) {
  const expected = new Map<string, string>([[
    "ProjectionType",
    "equirectangular",
  ]]);
  dimensions.forEach((name, i) =>
    expected.set(name, String([width, height, width, height, 0, 0][i]))
  );
  const found = new Set<string>();
  let element: { name: string; value: string } | null = null;
  const parser = new SaxesParser({ xmlns: true });
  function check(name: string, value: string) {
    const wanted = expected.get(name);
    if (wanted === undefined) return;
    const trimmed = value.trim();
    if (
      name === "ProjectionType"
        ? trimmed !== wanted
        : !/^\d+$/.test(trimmed) || Number(trimmed) !== Number(wanted)
    ) invalid();
    found.add(name);
  }
  parser.on("error", invalid);
  parser.on("doctype", invalid);
  parser.on("opentag", (tag) => {
    if (element) invalid();
    for (const attr of Object.values(tag.attributes)) {
      if (attr.uri === gpano) check(attr.local, attr.value);
    }
    if (tag.uri === gpano && expected.has(tag.local)) {
      element = { name: tag.local, value: "" };
    }
  });
  const append = (text: string) => {
    if (element) element.value += text;
  };
  parser.on("text", append);
  parser.on("cdata", append);
  parser.on("closetag", () => {
    if (!element) return;
    check(element.name, element.value);
    element = null;
  });
  parser.write(xml).close();
  if (found.size !== expected.size) invalid();
}

function validateOrientation(tiff: Uint8Array) {
  const little = startsWith(tiff, "II");
  if (tiff.length < 8 || (!little && !startsWith(tiff, "MM"))) invalid();
  const data = new DataView(tiff.buffer, tiff.byteOffset, tiff.length);
  if (data.getUint16(2, little) !== 42) invalid();
  const first = data.getUint32(4, little);
  if (first < 8 || first + 2 > tiff.length) invalid();
  const count = data.getUint16(first, little);
  if (first + 2 + count * 12 + 4 > tiff.length) invalid();
  for (let i = first + 2; i < first + 2 + count * 12; i += 12) {
    if (data.getUint16(i, little) !== 0x0112) continue;
    if (
      data.getUint16(i + 2, little) !== 3 ||
      data.getUint32(i + 4, little) !== 1 || data.getUint16(i + 8, little) !== 1
    ) invalid();
  }
}

/** Checks the JPEG structure and full-sphere declaration, then strips metadata.
 * Compaction is in place and never decodes or re-encodes the compressed pixels.
 */
export function prepareSphere(bytes: Uint8Array) {
  if (
    bytes.length < 4 || bytes.length > maxPanoramaBytes || bytes[0] !== 0xff ||
    bytes[1] !== 0xd8
  ) invalid();
  let offset = 2;
  let output = 2;
  let width = 0;
  let height = 0;
  let xmp: string | undefined;
  let scan = false;

  function keep(start: number, end: number) {
    if (output !== start) bytes.copyWithin(output, start, end);
    output += end - start;
  }

  while (offset < bytes.length) {
    const start = offset;
    if (bytes[offset++] !== 0xff) invalid();
    while (bytes[offset] === 0xff) offset++;
    const marker = bytes[offset++];
    if (marker === 0xd9) {
      if (!scan || !width || !xmp) invalid();
      validateProjection(xmp, width, height);
      keep(start, offset);
      return { width, height, bytes: bytes.subarray(0, output) };
    }
    if (marker === 0x01) {
      keep(start, offset);
      continue;
    }
    if (
      !marker || marker === 0xd8 || (marker >= 0xd0 && marker <= 0xd7) ||
      offset + 2 > bytes.length
    ) invalid();
    const length = bytes[offset] * 256 + bytes[offset + 1];
    if (length < 2 || offset + length > bytes.length) invalid();
    const data = bytes.subarray(offset + 2, offset + length);
    offset += length;

    if (marker === 0xc0 || marker === 0xc1 || marker === 0xc2) {
      const components = data[5];
      if (
        width || data[0] !== 8 || (components !== 1 && components !== 3) ||
        data.length !== 6 + components * 3
      ) invalid();
      height = data[1] * 256 + data[2];
      width = data[3] * 256 + data[4];
      if (height < 64 || width !== 2 * height) invalid();
      if (width > 8192) throw new Error("panorama_dimensions");
    }
    if (marker === 0xe1) {
      if (startsWith(data, xmpId)) {
        if (xmp !== undefined) invalid();
        xmp = new TextDecoder("utf-8", { fatal: true }).decode(
          data.subarray(xmpId.length),
        );
      } else if (startsWith(data, exifId)) {
        validateOrientation(data.subarray(exifId.length));
      }
    }
    if (marker === 0xda) {
      if (!width || !data[0] || data.length !== 4 + data[0] * 2) invalid();
      const scanStart = offset;
      while (true) {
        const next = bytes.indexOf(0xff, offset);
        if (next < 0) invalid();
        let code = next + 1;
        while (bytes[code] === 0xff) code++;
        const value = bytes[code];
        if (value === 0 || (value >= 0xd0 && value <= 0xd7)) {
          offset = code + 1;
        } else {
          offset = next;
          break;
        }
      }
      if (offset === scanStart) invalid();
      scan = true;
    }
    // APPn, comments and bytes after EOI may contain personal information.
    if (marker !== 0xfe && (marker < 0xe0 || marker > 0xef)) {
      keep(start, offset);
    }
  }
  return invalid();
}
