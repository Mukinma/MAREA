export function workerAuthorized(request: Request, secret: string): boolean {
 if (request.method !== 'POST' || secret.length < 32) return false;
 const supplied=request.headers.get('x-story-worker-secret') ?? '';
 if (supplied.length !== secret.length) return false;
 let difference=0;
 for(let i=0;i<secret.length;i++) difference|=supplied.charCodeAt(i)^secret.charCodeAt(i);
 return difference===0;
}
export async function cleanupBatch(
 rows: {id:string;image_path:string|null}[],
 removeImages: (paths:string[])=>Promise<void>,
 deleteRows: (ids:string[])=>Promise<void>,
) {
 const paths=rows.flatMap(row=>row.image_path?[row.image_path]:[]);
 if(paths.length) await removeImages(paths);
 if(rows.length) await deleteRows(rows.map(row=>row.id));
}
