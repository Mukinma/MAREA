import { strict as assert } from "node:assert";
import { clearTourStorage } from "./tour-storage.ts";
const files = new Set([
  "owner/capture/frame.jpg",
  "owner/jobs/job/panorama.jpg",
  "owner/jobs/job/preview.jpg",
  "owner/references/reference.jpg",
]);
const bucket = {
  async list(
    prefix: string,
    { offset, limit }: { offset: number; limit: number },
  ) {
    const children = new Map<string, { name: string; id: string | null }>();
    for (const file of files) {
      if (!file.startsWith(prefix + "/")) continue;
      const rest = file.slice(prefix.length + 1);
      const name = rest.split("/")[0];
      children.set(name, { name, id: rest.includes("/") ? null : "file" });
    }
    return {
      data: [...children.values()].slice(offset, offset + limit),
      error: null,
    };
  },
  async remove(paths: string[]) {
    paths.forEach((p) => files.delete(p));
    return { error: null };
  },
};
assert.equal(await clearTourStorage(bucket, "owner"), true);
assert.equal(files.size, 0, "nested tour originals and results are removed");
assert.equal(
  await clearTourStorage({
    ...bucket,
    list: async () => ({ data: null, error: "offline" }),
  }, "owner"),
  false,
  "failed storage never permits auth deletion",
);
assert.equal(
  await clearTourStorage({
    ...bucket,
    list: async () => ({
      data: [{ name: "../other", id: "file" }],
      error: null,
    }),
  }, "owner"),
  false,
  "bad returned path rejected",
);
console.log("3 recursive deletion assertions passed.");
