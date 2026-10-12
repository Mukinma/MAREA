// Storage list returns virtual folders with id=null. Walk the two nested private
// buckets before deleting the auth user; a failed cleanup leaves deletion marked.
export type StorageEntry = { name: string; id?: string | null };
type Bucket = {
  list(path: string, options: { limit: number; offset: number }): Promise<{
    data: StorageEntry[] | null;
    error: unknown;
  }>;
  remove(paths: string[]): Promise<{ error: unknown }>;
};
export async function clearTourStorage(
  bucket: Bucket,
  owner: string,
): Promise<boolean> {
  const todo = [owner];
  let visits = 0;
  while (todo.length) {
    const prefix = todo.pop()!;
    if (++visits > 10000 || prefix.split("/").length > 8) return false;
    let offset = 0;
    while (true) {
      const { data, error } = await bucket.list(prefix, { limit: 100, offset });
      if (error || !data) return false;
      const files: string[] = [];
      for (const entry of data) {
        // Never accept traversal in responses, even from Storage.
        if (
          !entry.name || /[\/\\]/.test(entry.name) ||
          [".", ".."].includes(entry.name)
        ) return false;
        const path = `${prefix}/${entry.name}`;
        if (entry.id) files.push(path);
        else todo.push(path);
      }
      if (files.length && (await bucket.remove(files)).error) return false;
      // Deleted leaves disappear from pagination; remaining virtual folders do not.
      offset += data.length - files.length;
      if (data.length < 100) break;
    }
  }
  return true;
}
