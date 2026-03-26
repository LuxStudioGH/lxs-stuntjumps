window.addEventListener('message', function(event) {
    if (event.data.action === "showSuccess") {
        const container = document.getElementById('success-container');
        const box = document.getElementById('animate-box');
        
        document.getElementById('title').innerText = event.data.title;
        document.getElementById('label-time').innerText = event.data.labelTime;
        document.getElementById('label-height').innerText = event.data.labelHeight;
        
        document.getElementById('time-val').innerText = event.data.time;
        document.getElementById('height-val').innerText = event.data.height;

        container.classList.remove('hidden');
        box.classList.remove('animate__fadeOutUp');
        box.classList.add('animate__animated', 'animate__backInDown');

        setTimeout(() => {
            box.classList.remove('animate__backInDown');
            box.classList.add('animate__fadeOutUp');
            
            setTimeout(() => {
                container.classList.add('hidden');
            }, 800);
        }, 4000);
    }
});