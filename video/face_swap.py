import sys,glob,cv2,numpy as np,onnxruntime as ort,os
import insightface
from insightface.app import FaceAnalysis
from insightface.utils import face_align
S=os.path.dirname(os.path.abspath(__file__))
app=FaceAnalysis(name='buffalo_l',providers=['CPUExecutionProvider'],allowed_modules=['detection','recognition','landmark_2d_106']);app.prepare(ctx_id=0,det_size=(640,640))
sw=insightface.model_zoo.get_model(S+'/models/inswapper_128.onnx',providers=['CPUExecutionProvider'])
gf=ort.InferenceSession(S+'/models/gfpgan_1.4.onnx',providers=['CPUExecutionProvider'])
gin=gf.get_inputs()[0].name
# source identity: barber from video 2
embs=[]
for f in ['src/s_10.jpg','src/s_11.jpg','src/s_12.jpg','src/s_06.jpg']:
    fs=app.get(cv2.imread(f)); fs=sorted(fs,key=lambda x:-(x.bbox[2]-x.bbox[0]))
    embs.append(fs[0].normed_embedding)
src=fs[0]; e=np.mean(embs,0); src.embedding=e/np.linalg.norm(e)*np.linalg.norm(fs[0].embedding)
# target identity: AI barber in video1 frame 1 (leftmost standing face)
f0=app.get(cv2.imread('v1/0001.png')); ref=sorted(f0,key=lambda x:x.bbox[1])[0].normed_embedding
FFHQ=np.array([[192.98138,239.94708],[318.90277,240.1936],[256.63416,314.01935],[201.26117,371.41043],[313.08905,371.15118]],np.float32)
def enhance(img,face):
    M,_=cv2.estimateAffinePartial2D(face.kps,FFHQ,method=cv2.LMEDS)
    crop=cv2.warpAffine(img,M,(512,512),borderMode=cv2.BORDER_REFLECT)
    x=(crop[:,:,::-1].astype(np.float32)/255-0.5)/0.5
    y=gf.run(None,{gin:x.transpose(2,0,1)[None]})[0][0]
    y=np.clip((y.transpose(1,2,0)+1)/2,0,1)[:,:,::-1]*255
    y=0.8*y+0.2*crop
    mask=np.zeros((512,512),np.float32); cv2.ellipse(mask,(256,280),(170,215),0,0,360,1,-1)
    mask=cv2.GaussianBlur(mask,(0,0),25)
    IM=cv2.invertAffineTransform(M); h,w=img.shape[:2]
    py=cv2.warpAffine(y.astype(np.float32),IM,(w,h)); pm=cv2.warpAffine(mask,IM,(w,h))[:,:,None]
    return (pm*py+(1-pm)*img).clip(0,255).astype(np.uint8)
files=sorted(glob.glob('v1/*.png'))
a,b=int(sys.argv[1]),int(sys.argv[2])
for f in files[a:b]:
    img=cv2.imread(f); out=img.copy()
    for fc in app.get(img):
        sim=float(np.dot(fc.normed_embedding,ref))
        if sim>0.35:
            out=sw.get(out,fc,src,paste_back=True)
            out=enhance(out,fc)
    cv2.imwrite('v1s/'+os.path.basename(f),out)
    print(f,[round(float(np.dot(fc.normed_embedding,ref)),2) for fc in app.get(img)][:3],flush=True)
