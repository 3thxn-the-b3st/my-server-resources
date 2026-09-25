window.addEventListener('message', function (event) {
    const data = event.data;
    const hud = document.getElementById('raid-hud');
    const tracker = document.getElementById('ambush-tracker');

    if (data.action === 'updateRoster') {
        if (hud) hud.classList.remove('hidden');

        const statusBadge = document.getElementById('hud-status-badge');
        const timerVal = document.getElementById('hud-timer');
        const list = document.getElementById('participant-list');
        const count = document.getElementById('roster-count');
        const footerHint = document.getElementById('hud-footer-hint');

        if (statusBadge && timerVal) {
            statusBadge.className = 'status-badge';
            if (data.stageText === 'LOBBY') {
                statusBadge.classList.add('lobby');
                statusBadge.innerText = 'LOBBY';
                timerVal.innerText = formatTime(data.timerVal || 0);

                if (footerHint) {
                    if (data.isPromptActive && !data.hasJoined) {
                        footerHint.classList.remove('hidden');
                    } else {
                        footerHint.classList.add('hidden');
                    }
                }
            } else if (data.stageText === 'CONTACT PHASE') {
                statusBadge.classList.add('contact');
                statusBadge.innerText = 'CONTACT NPC';
                timerVal.innerText = '--:--';
                if (footerHint) footerHint.classList.add('hidden');
            } else {
                statusBadge.classList.add('progress');
                statusBadge.innerText = 'IN PROGRESS';
                timerVal.innerText = formatTime(data.timerVal || 0);
                if (footerHint) footerHint.classList.add('hidden');
            }
        }

        if (list && count && data.participants) {
            list.innerHTML = '';
            count.innerText = `(${data.participants.length})`;
            data.participants.forEach(p => {
                const li = document.createElement('li');
                li.className = `player-item ${p.status === 'dead' ? 'dead' : ''}`;

                li.innerHTML = `
                    <span class="player-name">${p.name}</span>
                    <span class="player-status">${p.status === 'dead' ? '<i class="fa-solid fa-skull"></i> DEAD' : '<i class="fa-solid fa-check"></i> READY'}</span>
                `;
                list.appendChild(li);
            });
        }

    } else if (data.action === 'hide') {
        if (hud) {
            hud.classList.add('hidden');
        }
    } else if (data.action === 'updateAmbush') {
        if (tracker) tracker.classList.remove('hidden');
        const countElem = document.getElementById('ambush-count');
        if (countElem) {
            countElem.innerText = data.remaining;
            countElem.style.transform = 'scale(1.2)';
            setTimeout(() => { countElem.style.transform = 'scale(1)'; }, 150);
        }
    } else if (data.action === 'hideAmbush') {
        if (tracker) {
            tracker.classList.add('hidden');
        }
    }
});

function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins < 10 ? '0' : ''}${mins}:${secs < 10 ? '0' : ''}${secs}`;
}