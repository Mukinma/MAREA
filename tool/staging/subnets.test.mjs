import test from 'node:test';import assert from 'node:assert/strict';
import {overlaps} from './local-stack.mjs';
test('reject broader/subnet overlap, including nonaligned textual prefixes',()=>{assert.equal(overlaps('172.30.61.0/24','172.30.0.0/16'),true);assert.equal(overlaps('172.30.61.0/24','172.30.61.128/25'),true);assert.equal(overlaps('172.30.61.0/24','172.30.62.0/24'),false);assert.throws(()=>overlaps('invalid','172.30.61.0/24'));});
