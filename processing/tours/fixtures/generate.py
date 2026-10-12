"""Reproducible SYNTHETIC geometry fixtures, never evidence of phone/AR quality."""
import argparse
import json
import math
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw


def generate(destination):
    destination.mkdir(parents=True,exist_ok=True)
    rng=np.random.default_rng(360180)
    width,height=2048,1024
    # Unique seeded features across the sphere; rays share a fixed optical center.
    sphere=Image.fromarray(rng.integers(40,220,(height,width,3),dtype=np.uint8))
    draw=ImageDraw.Draw(sphere)
    for index in range(3200):
        x,y=map(int,rng.integers([0,0],[width,height]));size=int(rng.integers(3,25))
        color=tuple(map(int,rng.integers(0,256,3)))
        draw.rectangle((x,y,x+size,y+size),fill=color,outline='black',width=2)
        if index%4==0:draw.text((x,y),str(index),fill='white')
    texture=np.asarray(sphere)
    angles=[(yaw,0) for yaw in range(-180,180,30)]
    angles += [(yaw,pitch) for pitch in (-60,60) for yaw in range(-180,180,60)]
    angles += [(0,-90),(0,90)]
    size=640;hfov=90
    axis=(np.arange(size)+.5-size/2)/(size/2)*math.tan(math.radians(hfov/2))
    x,y=np.meshgrid(axis,-axis)
    rays=np.stack((x,y,np.ones_like(x)),axis=-1)
    frames=[]
    for index,(yaw,pitch) in enumerate(angles):
        a,b=map(math.radians,(yaw,pitch))
        # Rotate the forward vector upward by pitch, then around vertical by yaw.
        pitch_matrix=np.array([[1,0,0],[0,math.cos(b),math.sin(b)],[0,-math.sin(b),math.cos(b)]])
        yaw_matrix=np.array([[math.cos(a),0,math.sin(a)],[0,1,0],[-math.sin(a),0,math.cos(a)]])
        world=rays @ (yaw_matrix@pitch_matrix).T
        world/=np.linalg.norm(world,axis=-1,keepdims=True)
        lon=np.arctan2(world[:,:,0],world[:,:,2]);lat=np.arcsin(world[:,:,1])
        u=np.floor((lon/(2*math.pi)+.5)*width).astype(int)%width
        v=np.clip(np.floor((.5-lat/math.pi)*height).astype(int),0,height-1)
        file=f'frame{index:03d}.jpg'
        Image.fromarray(texture[v,u]).save(destination/file,quality=95)
        frames.append({'file':file,'width':size,'height':size,'yaw':yaw,'pitch':pitch,'roll':0,'hfov':hfov,'vfov':hfov})
    Image.new('RGB',(size,size),(128,128,128)).save(destination/'blank.jpg')
    (destination/'fixture.json').write_text(json.dumps({'kind':'synthetic-ray-projection-test-data','seed':360180,'frames':frames},indent=2))
    (destination/'NOTICE.txt').write_text('Synthetic geometric test data. No phone capture, optical calibration, physical place, person or AR tracking.\n')
    return frames
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('destination',type=Path);args=parser.parse_args();generate(args.destination)
