const progress = document.getElementById('progressBar');
const reveals = document.querySelectorAll('.reveal');
const scenes = document.querySelectorAll('.scene');

function clamp(n,min,max){return Math.max(min,Math.min(max,n));}
function onScroll(){
  const max=document.documentElement.scrollHeight-window.innerHeight;
  const y=window.scrollY;
  progress.style.width=(max?y/max*100:0)+'%';
  reveals.forEach(el=>{if(el.getBoundingClientRect().top<window.innerHeight*.86)el.classList.add('visible')});
  scenes.forEach((scene,index)=>{
    const rect=scene.getBoundingClientRect();
    const total=Math.max(1,scene.offsetHeight-window.innerHeight);
    const p=clamp(-rect.top/total,0,1);
    scene.style.setProperty('--scroll-progress',p.toFixed(3));
    const visual=scene.querySelector('.scene-visual');
    if(visual && scene.classList.contains('cinema')){
      const shift=(p-.5)*70;
      visual.style.transform=`translate3d(${shift}px,${-shift*.18}px,0) scale(${1+Math.abs(p-.5)*.06})`;
    }
    const copy=scene.querySelector('.scene-copy');
    if(copy && scene.classList.contains('cinema')){
      copy.style.opacity=String(.45+Math.sin(p*Math.PI)*.55);
      copy.style.transform=`translate3d(${(p-.5)*-28}px,0,0)`;
    }
  });
}
window.addEventListener('scroll',onScroll,{passive:true});
window.addEventListener('resize',onScroll);
onScroll();

// Smooth anchor navigation without external libraries.
document.querySelectorAll('a[href^="#"]').forEach(a=>a.addEventListener('click',e=>{
  const target=document.querySelector(a.getAttribute('href'));
  if(!target)return;
  e.preventDefault();
  target.scrollIntoView({behavior:'smooth',block:'start'});
}));
