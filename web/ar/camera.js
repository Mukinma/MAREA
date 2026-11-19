// Private reference images and live frames stay inside this browser tab.
window.mareaImageTracker = {
  supported() {
    return !!(isSecureContext && navigator.mediaDevices?.getUserMedia && window.Worker);
  },
  start(video, bytes, callback) {
    let closed=false, stream, timer, worker, lastTime=-1;
    const stop=()=>{
      closed=true;
      clearTimeout(timer);
      worker?.terminate();
      stream?.getTracks().forEach(track=>track.stop());
      video.srcObject=null;
    };
    const fail=message=>{ if(!closed) callback('error',null,message); stop(); };
    video.style.cssText='width:100%;height:100%;object-fit:contain;background:#000;pointer-events:none';
    video.muted=true; video.playsInline=true;
    const canvas=document.createElement('canvas');
    const ctx=canvas.getContext('2d',{willReadFrequently:true});
    function pixels(source,w,h,max) {
      const scale=max/Math.max(w,h);
      canvas.width=Math.max(1,Math.round(w*scale));
      canvas.height=Math.max(1,Math.round(h*scale));
      ctx.drawImage(source,0,0,canvas.width,canvas.height);
      return ctx.getImageData(0,0,canvas.width,canvas.height);
    }
    function next() {
      if(closed) return;
      if(!video.videoWidth || video.currentTime===lastTime) {timer=setTimeout(next,100);return;}
      lastTime=video.currentTime;
      const frame=pixels(video,video.videoWidth,video.videoHeight,480);
      worker.postMessage({frame},[frame.data.buffer]);
    }
    async function prepare() {
      const image=new Image();
      const url=URL.createObjectURL(new Blob([bytes]));
      try {
        image.src=url; await image.decode();
        if(closed) return;
        const refs=[180,300,440].map(size=>pixels(image,image.naturalWidth,image.naturalHeight,size));
        worker=new Worker(new URL('ar/tracker.js',document.baseURI));
        worker.onerror=()=>fail('No se pudo iniciar el reconocimiento.');
        worker.onmessage=async ({data})=>{
          if(closed) return;
          try {
            if('ready' in data) {
              if(!data.ready) {fail('La referencia necesita más detalles visibles.');return;}
              stream=await navigator.mediaDevices.getUserMedia({audio:false,video:{facingMode:{ideal:'environment'},width:{ideal:960}}});
              if(closed) {stop();return;}
              video.srcObject=stream; await video.play(); next();
            } else {
              let quad=data.quad;
              if(quad && video.clientWidth && video.clientHeight) {
                const scale=Math.min(video.clientWidth/video.videoWidth,video.clientHeight/video.videoHeight);
                const w=video.videoWidth*scale/video.clientWidth, h=video.videoHeight*scale/video.clientHeight;
                quad=quad.map((v,i)=>i%2 ? (1-h)/2+v*h : (1-w)/2+v*w);
              }
              callback(quad?'tracking':'lost',quad,null);
              timer=setTimeout(next,60);
            }
          } catch { fail('No se pudo abrir la cámara. Revisa el permiso del navegador.'); }
        };
        worker.postMessage({references:refs},refs.map(r=>r.data.buffer));
      } finally { URL.revokeObjectURL(url); }
    }
    prepare().catch(()=>fail('No se pudo leer la imagen de referencia.'));
    return stop;
  }
};
