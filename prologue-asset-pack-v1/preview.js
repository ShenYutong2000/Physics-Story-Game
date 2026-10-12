const $=s=>document.querySelector(s), assets=new Map(ASSET_MANIFEST.assets.map(a=>[a.id,a])), images=new Map();
const cv=$("#stage"),ctx=cv.getContext("2d"),av=$("#animation"),ac=av.getContext("2d"); let scene=SCENES[0],states={},hits=[],selectedAnim="kath-idle",audio=null,audioPlaying=false,messageTimer;
function get(id){const a=assets.get(id);if(!a)return null;if(!images.has(id)){const im=new Image();im.src=a.file;images.set(id,im);}return images.get(id);}
function ready(im){return im&&im.complete&&im.naturalWidth>0;}
function full(id){const im=get(id);if(ready(im))ctx.drawImage(im,0,0,1672,941);}
function sprite(c,id,x,y,h,frame=0,alpha=1,flip=false){const a=assets.get(id),im=get(id);if(!a||!ready(im))return null;const f=a.frames?.[frame%a.frames.length];const r=f?f.region:a.bounds;let w,dh,dx,dy;
 if(f){const scale=h/a.canvas[1];w=r[2]*scale;dh=r[3]*scale;dx=x-a.canvas[0]*scale/2+f.offset[0]*scale;dy=y-a.canvas[1]*scale+f.offset[1]*scale;}
 else{dh=h;w=r[2]*h/r[3];dx=x-w/2;dy=y-h;}
 c.save();c.globalAlpha=alpha;if(flip){c.translate(x*2,0);c.scale(-1,1);}c.drawImage(im,...r,dx,dy,w,dh);c.restore();return {x:dx,y:dy,w,h:dh};}
function rawRotate(id,pivotSource,target,scale,angle){const im=get(id);if(!ready(im))return;ctx.save();ctx.translate(...target);ctx.rotate(angle);ctx.scale(scale,scale);ctx.drawImage(im,-pivotSource[0],-pivotSource[1]);ctx.restore();}
function message(text){$("#message").textContent=text;$("#message").style.display="block";clearTimeout(messageTimer);messageTimer=setTimeout(()=>$("#message").style.display="none",4200);}
function sound(name,loop=false){if(loop){if(audio)audio.pause();audio=new Audio("audio/"+name+".wav");audio.loop=true;audio.volume=.35;audio.play().catch(()=>{});return;}const a=new Audio("audio/"+name+".wav");a.volume=.4;a.play().catch(()=>{});}
function setScene(s){scene=s;states={};document.querySelectorAll("#scene-tabs button").forEach((b,i)=>b.classList.toggle("active",SCENES[i]===s));$("#scene-title").textContent=s.id+" / "+s.name;$("#scene-story").textContent=s.story;$("#message").style.display="none";if(audioPlaying)sound(scene.audio,true);}
SCENES.forEach(s=>{const b=document.createElement("button");b.textContent=s.id+" "+s.zh;b.onclick=()=>setScene(s);$("#scene-tabs").appendChild(b);});
$("#reset").onclick=()=>{states={};};$("#ambience").onclick=()=>{audioPlaying=!audioPlaying;$("#ambience").textContent=audioPlaying?"停止环境音":"播放环境音";if(audioPlaying)sound(scene.audio,true);else audio?.pause();};
cv.addEventListener("click",e=>{const b=cv.getBoundingClientRect(),x=(e.clientX-b.left)*1672/b.width,y=(e.clientY-b.top)*941/b.height;const hit=[...hits].reverse().find(h=>x>=h.x&&x<=h.x+h.w&&y>=h.y&&y<=h.y+h.h);if(!hit)return;const p=hit.prop;if(p.cycle){states[hit.key]=((states[hit.key]||0)+1)%assets.get(p.id).frames.length;sound(p.id.includes("case")?"case-open":p.id.includes("gate")?"gate-latch":"lever-click");}message(p.tip||p.id.replaceAll("-"," ")+" · "+(assets.get(p.id).frames?.[states[hit.key]||0]?.name||""));if(p.id==="wooden-case-states"&&states[hit.key]===2)message("F = ma. These letters are in my own handwriting.");});
function render(ms){const t=ms/1000;ctx.clearRect(0,0,1672,941);ctx.fillStyle="#242c46";ctx.fillRect(0,0,1672,941);
 if($("#layered").checked){full(scene.far);if(scene.id==="05"){ctx.strokeStyle="#b78c4c";ctx.lineWidth=6;ctx.beginPath();ctx.moveTo(1287,190);ctx.lineTo(1595,190);ctx.stroke();rawRotate("castle-wing-upright",[627,1047],[1441,190],.151,Math.PI);}full(scene.mid);}
 else{full(scene.bg);if(scene.id==="05"){ctx.strokeStyle="#b78c4c";ctx.lineWidth=6;ctx.beginPath();ctx.moveTo(1287,190);ctx.lineTo(1595,190);ctx.stroke();rawRotate("castle-wing-upright",[627,1047],[1441,190],.151,Math.PI);}}
 hits=[];if($("#props").checked){scene.props.forEach((p,i)=>{const key=p.id+"-"+i,r=sprite(ctx,p.id,p.x,p.y,p.h,states[key]||0);if(r)hits.push({...r,prop:p,key});});
 if(scene.id==="01"){rawRotate("clock-hand",[474,1420],[967,455],.054,t*.11);rawRotate("clock-pendulum",[512,90],[967,506],.105,Math.sin(t*2.1)*.12);}
 if(scene.id==="02"){let needle=-.82+Math.sin(t*.8)*.14;if(states["lever-states-5"]&&states["lever-states-7"])needle=-1.5;rawRotate("gauge-needle",[183,636],[1136,269],.043,needle);}
 if(scene.id==="03"&&states["wooden-case-states-1"]===2)sprite(ctx,"newton-note",1012,375,93);}
 if($("#effects").checked){if(scene.id==="03"){const dy=170+(t*120)%455;sprite(ctx,"rain-drop",1420,dy,11,.0,.7);sprite(ctx,"water-ripple",1420,655,14,Math.floor(t*6)%4,.6);}
 if(scene.id==="02")sprite(ctx,"steam-puff",514,310-(t*19)%80,92,Math.floor(t*3)%4,.18);
 if(scene.id==="05")sprite(ctx,"valley-fog",1050+Math.sin(t*.1)*30,648,72,0,.18);}
 if($("#characters").checked){const id=$("#action").value,aa=assets.get(id),f=Math.floor(t*aa.suggested_fps)%aa.frames.length;sprite(ctx,id,scene.playerX,scene.floor,232,f);sprite(ctx,"wick-flight-v2",scene.playerX+82,scene.floor-193+Math.sin(t*2)*6,48,Math.floor(t*8)%4);
 if(scene.id==="01")sprite(ctx,"keeper-idle-talk",1140,778,224,0);}
 if($("#foreground").checked)full(scene.front);
 ac.clearRect(0,0,420,460);const aa=assets.get(selectedAnim),frame=Math.floor(t*aa.suggested_fps)%aa.frames.length;sprite(ac,selectedAnim,210,443,405,frame);requestAnimationFrame(render);}
const anims=ASSET_MANIFEST.assets.filter(a=>a.category==="characters");anims.forEach(a=>{const o=document.createElement("option");o.value=a.id;o.textContent=a.id;$("#anim-select").appendChild(o);});$("#anim-select").onchange=e=>selectedAnim=e.target.value;
const groups={all:"全部",backgrounds:"完整背景",far:"远景",mid:"透明中景",foregrounds:"前景",props:"道具",characters:"角色",effects:"效果",ui:"界面"};
function gallery(category){$("#gallery").replaceChildren();ASSET_MANIFEST.assets.filter(a=>category==="all"||a.category===category).forEach(a=>{const d=document.createElement("div");d.className="card";const link=document.createElement("a");link.href=a.file;link.target="_blank";const im=document.createElement("img");im.className="checker";im.loading="lazy";im.src=a.file;im.alt=a.id;link.appendChild(im);const body=document.createElement("div");body.className="card-body";const title=document.createElement("strong");title.textContent=a.id;const detail=document.createElement("small");detail.textContent=a.width+" × "+a.height+" · "+(a.has_alpha?"透明 PNG":"不透明 PNG")+(a.frames?" · "+a.frames.length+" 帧":"");const dl=document.createElement("a");dl.href=a.file;dl.download="";dl.textContent="保存 PNG ↗";body.append(title,detail,dl);d.append(link,body);$("#gallery").appendChild(d);});}
for(const [id,label]of Object.entries(groups)){const b=document.createElement("button");b.textContent=label;b.classList.toggle("active",id==="all");b.onclick=()=>{document.querySelectorAll("#filters button").forEach(el=>el.classList.remove("active"));b.classList.add("active");gallery(id);};$("#filters").appendChild(b);}
const audios={"amb-library":"书库 · 雨声","amb-machine":"机械室 · 低鸣","amb-room":"卧室 · 空气","amb-road":"维修路 · 风声","step-wood":"木地板脚步","step-stone":"石路脚步","lever-click":"手柄拨动","clock-tick":"钟表滴答","case-open":"开匣","gate-latch":"门闩","stop-switch":"停机按钮","ladder-step":"梯子脚步","page-turn":"翻页","water-drop":"水滴","pencil-write":"书写","wick-flutter":"Wick 振翅"};
for(const[id,label]of Object.entries(audios)){const b=document.createElement("button");b.textContent="▷ "+label;b.onclick=()=>sound(id);$("#audio-list").appendChild(b);}
setScene(scene);gallery("all");requestAnimationFrame(render);

