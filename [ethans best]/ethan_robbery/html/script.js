let countdownInterval = null;

window.addEventListener('message', function(event) {
    let data = event.data;
    
    if (data.action === "updateLobby") {
        let container = document.getElementById('lobby-container');
        
        if (data.display) {
            container.classList.remove('hidden');
            
            // Set Dynamic Header Title ("ROBBERY LOBBY" or "ROBBERY IN PROGRESS")
            let titleElement = document.getElementById('status-title');
            if (titleElement) {
                titleElement.textContent = data.status || "ROBBERY LOBBY";
            }

            // Update Participant List
            let list = document.getElementById('member-list');
            list.innerHTML = '';
            if (data.members) {
                data.members.forEach(function(member) {
                    let li = document.createElement('li');
                    li.textContent = member;
                    list.appendChild(li);
                });
            }

            // Reset active countdown interval
            if (countdownInterval) {
                clearInterval(countdownInterval);
            }

            // Start Live 1-second Countdown Loop
            let timeRemaining = parseInt(data.timer) || 30;
            document.getElementById('time').textContent = timeRemaining;

            countdownInterval = setInterval(function() {
                timeRemaining--;
                if (timeRemaining >= 0) {
                    document.getElementById('time').textContent = timeRemaining;
                } else {
                    clearInterval(countdownInterval);
                }
            }, 1000);

        } else {
            container.classList.add('hidden');
            if (countdownInterval) {
                clearInterval(countdownInterval);
            }
        }
    }
});