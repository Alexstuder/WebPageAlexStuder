(function(){
  const OVERLAY_DURATION = 20000;
  const FADE_OFFSET = 1800;
  const FIREWORKS = 28;
  const SPARKS = 12;

  function prefersReducedMotion(){
    return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  function clearExisting(){
    const existing=document.querySelector('.celebration-overlay');
    if(existing){ existing.remove(); }
  }

  function createOverlay(reduced){
    const overlay=document.createElement('div');
    overlay.className='celebration-overlay'+(reduced?' reduced':'');
    overlay.setAttribute('aria-hidden','true');
    return overlay;
  }

  function createFirework(delay){
    const fw=document.createElement('span');
    fw.className='firework';
    fw.style.left=`${Math.random()*84+8}%`;
    fw.style.top=`${Math.random()*60+10}%`;
    fw.style.animationDelay=`${delay.toFixed(2)}s`;
    fw.style.setProperty('--h', Math.floor(Math.random()*360));
    return fw;
  }

  function createSpark(delay){
    const spark=document.createElement('span');
    spark.className='spark';
    spark.style.left=`${Math.random()*92+4}%`;
    spark.style.animationDelay=`${delay.toFixed(2)}s`;
    spark.style.setProperty('--spark-x', `${(Math.random()*1.6-0.8).toFixed(2)}vw`);
    spark.style.setProperty('--spark-h', Math.floor(Math.random()*360));
    return spark;
  }

  function buildPlane(text, top, delay, variant){
    const plane=document.createElement('div');
    plane.className=`plane ${variant||''}`.trim();
    plane.style.setProperty('--plane-top', top);
    plane.style.animationDelay=`${delay}s`;

    const body=document.createElement('div');
    body.className='plane-body';

    const tail=document.createElement('span');
    tail.className='plane-tail';

    const wingTop=document.createElement('span');
    wingTop.className='plane-wing plane-wing-top';

    const wingBottom=document.createElement('span');
    wingBottom.className='plane-wing plane-wing-bottom';

    const cockpit=document.createElement('span');
    cockpit.className='plane-cockpit';

    const pilot=document.createElement('span');
    pilot.className='plane-pilot';
    const pilotFace=document.createElement('span');
    pilotFace.className='plane-pilot-face';
    pilot.appendChild(pilotFace);
    cockpit.appendChild(pilot);

    const windows=document.createElement('span');
    windows.className='plane-window-strip';

    const prop=document.createElement('span');
    prop.className='plane-prop';

    body.append(tail, wingTop, wingBottom, cockpit, windows, prop);

    const banner=document.createElement('div');
    banner.className='plane-banner';
    const bannerText=document.createElement('span');
    bannerText.textContent=text;
    banner.appendChild(bannerText);

    const rope=document.createElement('span');
    rope.className='plane-rope';

    plane.append(body, rope, banner);
    return plane;
  }

  function buildReducedContent(overlay){
    const box=document.createElement('div');
    box.className='celebration-message';
    const heading=document.createElement('strong');
    heading.textContent='Congratulation.';
    const line=document.createElement('div');
    line.textContent='Fast so schön wie schtudi';
    box.append(heading,line);
    overlay.appendChild(box);
  }

  window.triggerCelebration=function(){
    clearExisting();
    const reduced=prefersReducedMotion();
    const overlay=createOverlay(reduced);

    if(reduced){
      buildReducedContent(overlay);
    } else {
      for(let i=0;i<FIREWORKS;i++){
        const delay=Math.random()*0.28+i*0.16;
        overlay.appendChild(createFirework(delay));
      }
      for(let j=0;j<SPARKS;j++){
        const delay=Math.random()*0.3+j*0.35;
        overlay.appendChild(createSpark(delay));
      }
      const plane1=buildPlane('Congratulation.', '18%', 0, 'plane-main');
      const plane2=buildPlane('Fast so schön wie schtudi', '52%', 5.8, 'plane-secondary');
      plane1.style.setProperty('--plane-duration','16s');
      plane2.style.setProperty('--plane-duration','17.5s');
      overlay.append(plane1, plane2);
    }

    document.body.appendChild(overlay);
    requestAnimationFrame(()=>overlay.classList.add('show'));

    const duration=reduced?4000:OVERLAY_DURATION;
    setTimeout(()=>overlay.classList.add('fade'), Math.max(0,duration-FADE_OFFSET));
    setTimeout(()=>overlay.remove(), duration);
  };
})();
