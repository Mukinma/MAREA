import { assertEquals, assertThrows } from "jsr:@std/assert@1.0.16";
import { prepareSphere } from "./panorama.ts";

const jpegData =
  "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wgARCABAAIADASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAT/xAAVAQEBAAAAAAAAAAAAAAAAAAAABf/aAAwDAQACEAMQAAABhFKUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB//8QAFBABAAAAAAAAAAAAAAAAAAAAcP/aAAgBAQABBQIA/8QAFBEBAAAAAAAAAAAAAAAAAAAAUP/aAAgBAwEBPwED/8QAFBEBAAAAAAAAAAAAAAAAAAAAUP/aAAgBAgEBPwED/8QAFBABAAAAAAAAAAAAAAAAAAAAcP/aAAgBAQAGPwIA/8QAFBABAAAAAAAAAAAAAAAAAAAAcP/aAAgBAQABPyEA/9oADAMBAAIAAwAAABD77777777777777777777777777777777/xAAUEQEAAAAAAAAAAAAAAAAAAABQ/9oACAEDAQE/EAP/xAAUEQEAAAAAAAAAAAAAAAAAAABQ/9oACAECAQE/EAP/xAAUEAEAAAAAAAAAAAAAAAAAAABw/9oACAEBAAE/EAD/2Q==";
const jpeg = Uint8Array.from(atob(jpegData), (char) => char.charCodeAt(0));
const text = (value: string) => new TextEncoder().encode(value);
const metadata = `<photo xmlns:p="http://ns.google.com/photos/1.0/panorama/"
 p:ProjectionType="equirectangular" p:FullPanoWidthPixels="128"
 p:FullPanoHeightPixels="64" p:CroppedAreaImageWidthPixels="128"
 p:CroppedAreaImageHeightPixels="64" p:CroppedAreaLeftPixels="0">
 <p:CroppedAreaTopPixels>0</p:CroppedAreaTopPixels></photo>`;

function concat(...parts: Uint8Array[]) {
  const result = new Uint8Array(
    parts.reduce((size, part) => size + part.length, 0),
  );
  let offset = 0;
  for (const part of parts) {
    result.set(part, offset);
    offset += part.length;
  }
  return result;
}

function segment(marker: number, bytes: Uint8Array) {
  const length = bytes.length + 2;
  return concat(Uint8Array.of(0xff, marker, length >> 8, length & 255), bytes);
}

function panorama(xml = metadata, ...extras: Uint8Array[]) {
  return concat(
    jpeg.subarray(0, 2),
    segment(0xe1, text(`http://ns.adobe.com/xap/1.0/\0${xml}`)),
    ...extras,
    jpeg.subarray(2),
  );
}

Deno.test("a progressive sphere retains its compressed pixels and removes all metadata", () => {
  const input = panorama(
    metadata,
    segment(0xe2, text("private camera details")),
  );
  const output = prepareSphere(
    concat(
      input.subarray(0, -2),
      segment(0xfe, text("private comment")),
      input.subarray(-2),
      text("trailing bytes"),
    ),
  );
  assertEquals([output.width, output.height], [128, 64]);
  // Pillow's original JPEG has only a JFIF APP0 segment before its coding tables.
  assertEquals(output.bytes, concat(jpeg.subarray(0, 2), jpeg.subarray(20)));
});

Deno.test("a flat 2:1 JPEG, a crop and a spoofed GPano namespace cannot become spheres", () => {
  for (
    const input of [
      jpeg.slice(),
      panorama(
        metadata.replace(
          'CroppedAreaLeftPixels="0"',
          'CroppedAreaLeftPixels="4"',
        ),
      ),
      panorama(
        metadata.replace(
          "http://ns.google.com/photos/1.0/panorama/",
          "https://example.invalid/gpano",
        ),
      ),
      panorama().slice(0, -2),
    ]
  ) assertThrows(() => prepareSphere(input), Error, "invalid_panorama");
});

Deno.test("rotated EXIF must be normalized before making a viewer asset", () => {
  const rotated = Uint8Array.of(
    73,
    73,
    42,
    0,
    8,
    0,
    0,
    0,
    1,
    0,
    0x12,
    0x01,
    3,
    0,
    1,
    0,
    0,
    0,
    6,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  );
  const input = panorama(
    metadata,
    segment(0xe1, concat(text("Exif\0\0"), rotated)),
  );
  assertThrows(() => prepareSphere(input), Error, "invalid_panorama");
});
