import assert from 'node:assert/strict';
import {test} from 'node:test';
import {cleanupBatch, workerAuthorized} from './cleanup.ts';
test('a failed media removal retains the story for retry', async () => {
 let deleted = false;
 await assert.rejects(cleanupBatch([{id:'story', image_path:'user/story.png'}], async () => { throw Error('storage offline'); }, async () => { deleted=true; }));
 assert.equal(deleted,false);
});
test('images are removed before their rows and text-only stories are cleaned',async () => {
 const order:string[]=[];
 await cleanupBatch([{id:'photo',image_path:'user/photo.png'},{id:'text',image_path:null}],async paths => {assert.deepEqual(paths,['user/photo.png']);order.push('media');},async ids => {assert.deepEqual(ids,['photo','text']);order.push('rows');});
 assert.deepEqual(order,['media','rows']);
});
test('cleanup is inaccessible without the server-only secret', () => {
 assert.equal(workerAuthorized(new Request('https://example.com',{method:'POST'}),'x'.repeat(32)),false);
 assert.equal(workerAuthorized(new Request('https://example.com',{method:'POST',headers:{'x-story-worker-secret':'x'.repeat(32)}}),'x'.repeat(32)),true);
 assert.equal(workerAuthorized(new Request('https://example.com',{method:'GET',headers:{'x-story-worker-secret':'x'.repeat(32)}}),'x'.repeat(32)),false);
 assert.equal(workerAuthorized(new Request('https://example.com',{method:'POST',headers:{'x-story-worker-secret':'abc'}}),'abc'),false);
});
