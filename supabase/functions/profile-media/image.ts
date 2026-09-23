import { PNG } from 'npm:pngjs@7.0.0';
import { Buffer } from 'node:buffer';
export function ownsPath(owner: string, path: unknown): path is string {
  return typeof path === 'string' && path.startsWith(`${owner}/`) && /^[0-9a-f-]{36}\/[0-9a-f-]{36}\.png$/.test(path);
}
export function validateAndNormalizePng(bytes: Uint8Array): Buffer {
  if (bytes.length < 33 || bytes.length > 4194304) throw new Error('invalid_image');
  const buffer = Buffer.from(bytes);
  if (buffer.subarray(0,8).toString('hex') !== '89504e470d0a1a0a' || buffer.toString('ascii',12,16) !== 'IHDR') throw new Error('invalid_image');
  const width = buffer.readUInt32BE(16), height = buffer.readUInt32BE(20);
  if (width < 1 || height < 1 || width > 1600 || height > 1600) throw new Error('image_dimensions');
  const decoded = PNG.sync.read(buffer, {checkCRC: true});
  const normalized = PNG.sync.write(decoded);
  if (normalized.length > 4194304) throw new Error('image_size');
  return normalized;
}
