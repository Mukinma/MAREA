// jsfeat 0.0.8 (MIT). Work on a reduced frame in a dedicated worker.
importScripts('vendor/jsfeat-0.0.8.min.js');
const type = jsfeat.U8_t | jsfeat.C1_t;
const bitCount = Uint8Array.from({length: 256}, (_, n) => n.toString(2).replaceAll('0','').length);
let targets = [];
let corners = [];
function features(image) {
  const {width, height, data} = image;
  const gray = new jsfeat.matrix_t(width, height, type);
  jsfeat.imgproc.grayscale(data, width, height, gray);
  // yape06 writes into caller-provided corner objects.
  while (corners.length < width * height / 3 + 1) corners.push({});
  const count = jsfeat.yape06.detect(gray, corners, 17);
  const points = corners.slice(0, count).sort((a,b) => b.score-a.score).slice(0, 340)
    .map(({x,y}) => {
      let mx=0, my=0;
      for(let dy=-8; dy<=8; dy++) {
        const span = Math.floor(Math.sqrt(64-dy*dy));
        for(let dx=-span; dx<=span; dx++) {
          const v=gray.data[(y+dy)*width+x+dx];
          mx+=v*dx; my+=v*dy;
        }
      }
      return {x,y,angle: Math.atan2(my,mx)};
    });
  const descriptors = new jsfeat.matrix_t(32, points.length, type);
  jsfeat.orb.describe(gray, points, points.length, descriptors);
  return {width,height,points,bytes:descriptors.data};
}
function locate(target, frame) {
  const matches = new Map();
  for(let i=0;i<frame.points.length;i++) {
    let first=257, second=257, index=-1;
    for(let j=0;j<target.points.length;j++) {
      let distance=0;
      for(let k=0;k<32 && distance<second;k++) {
        distance+=bitCount[frame.bytes[i*32+k]^target.bytes[j*32+k]];
      }
      if(distance<first) { second=first; first=distance; index=j; }
      else if(distance<second) second=distance;
    }
    if(first<60 && first<second*.75 && first<(matches.get(index)?.distance ?? Infinity)) {
      matches.set(index,{distance:first,point:frame.points[i]});
    }
  }
  const from=[], to=[];
  for(const [idx,match] of matches) {from.push(target.points[idx]); to.push(match.point);}
  if(from.length<12) return null;
  const kernel=new jsfeat.motion_model.homography2d();
  const model=new jsfeat.matrix_t(3,3,jsfeat.F32_t|jsfeat.C1_t);
  const mask=new jsfeat.matrix_t(from.length,1,type);
  const params=new jsfeat.ransac_params_t(4,2.5,.5,.99);
  if(!jsfeat.motion_estimator.ransac(params,kernel,from,to,from.length,model,mask,350)) return null;
  const good=from.filter((_,i)=>mask.data[i]);
  if(good.length<12 || good.length<from.length*.55) return null;
  for(const [axis,size] of [['x',target.width],['y',target.height]]) {
    const coords=good.map(p=>p[axis]);
    if(Math.max(...coords)-Math.min(...coords)<size*.27) return null;
  }
  const inliers=to.filter((_,i)=>mask.data[i]);
  if(!kernel.run(good,inliers,model,good.length)) return null;
  const h=model.data;
  const quad=[];
  for(const [x,y] of [[0,0],[target.width,0],[target.width,target.height],[0,target.height]]) {
    const w=h[6]*x+h[7]*y+h[8];
    if(w<.01) return null;
    const px=(h[0]*x+h[1]*y+h[2])/w/frame.width;
    const py=(h[3]*x+h[4]*y+h[5])/w/frame.height;
    if(!Number.isFinite(px+py) || px<-.2 || py<-.2 || px>1.2 || py>1.2) return null;
    quad.push(px,py);
  }
  for(let i=0;i<8;i+=2) {
    const j=(i+2)%8,k=(i+4)%8;
    const cross=(quad[j]-quad[i])*(quad[k+1]-quad[j+1])-(quad[j+1]-quad[i+1])*(quad[k]-quad[j]);
    if(cross<.007) return null;
  }
  return quad;
}
self.onmessage = ({data}) => {
  if(data.references) {
    targets=data.references.map(features);
    self.postMessage({ready:targets.some(t=>t.points.length>=12)});
  } else {
    const frame=features(data.frame);
    let quad=null;
    for(const target of targets) { quad=locate(target,frame); if(quad) break; }
    self.postMessage({quad});
  }
};
