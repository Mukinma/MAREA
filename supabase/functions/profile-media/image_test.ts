import { validateAndNormalizePng, ownsPath } from './image.ts';
import { PNG } from 'npm:pngjs@7.0.0';
function assert(value: boolean) { if (!value) throw new Error('Assertion failed'); }
Deno.test('rejects invalid image bytes and oversized headers', () => {
  for (const bytes of [new Uint8Array([1,2,3]), new Uint8Array(4194305)]) {
    let rejected = false; try { validateAndNormalizePng(bytes); } catch { rejected = true; }
    assert(rejected);
  }
});
Deno.test('normalizes a valid small PNG', () => {
  const original = PNG.sync.write(new PNG({width: 2, height: 2}));
  const encoded = validateAndNormalizePng(original);
  const decoded = PNG.sync.read(encoded);
  assert(decoded.width === 2 && decoded.height === 2);
});
Deno.test('path validation rejects other owners and traversal', () => {
  const id = '11111111-1111-4111-8111-111111111111';
  assert(ownsPath(id, `${id}/22222222-2222-4222-8222-222222222222.png`));
  assert(!ownsPath(id, '../other.png'));
  assert(!ownsPath(id, 'other/22222222-2222-4222-8222-222222222222.png'));
});
