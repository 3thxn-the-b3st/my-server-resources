$(".center h1").html(name);
$(".center p").html(underName);
$(".center span").html(desc);

var serverInfo = null;

function loading(num) {
	let current = parseInt($(".loading-bar p").text(), 10) || 0;
	const step = 1;
	const delay = 700 / Math.abs(num - current);

	const interval = setInterval(function () {
		if (current < num) {
			current += step;
			if (current > num) current = num;
		} else if (current > num) {
			current -= step;
			if (current < num) current = num;
		} else {
			clearInterval(interval);
		}
		$(".loading-bar p").text(current + "%");
	}, delay);

	$(".loading-bar .line").width(num + "%");
}

if (showStaffTeam) {
	$(".panel.staffteam").show();
	staff_team.forEach(function (user) {
		$(".staff_team").append(`
			<div class="staff">
				<div class="info">
					<img src="${user.image}" class="pfp">
					<p>${user.name}</p>
				</div>
				<p class="status">${user.rank}</p>
			</div>
		`);
	});
}

if (showTipList) {
	$(".panel.panelInfo").show();
}

if (musicConfig.enabled && musicConfig.showMusicPlayer) {
	$(".music-player").show();
	$(".music-info .artist").text(musicConfig.artist);
	$(".music-info .song-title").text(musicConfig.songTitle);
}

window.addEventListener("message", function (e) {
	if (e.data.eventName === "loadProgress") {
		var num = (e.data.loadFraction * 100).toFixed(0);
		loading(num);
	}
});

const socials = { discord, instagram, youtube, twitter, tiktok, facebook, twitch, github };
const platforms = ["discord", "instagram", "youtube", "twitter", "tiktok", "facebook", "twitch", "github"];

platforms.forEach(function (platform) {
	if (socials[platform] != "") {
		$(`.${platform}`).show();
		$(`.${platform} a`).attr("href", socials[platform]);
	}
});

$("a").on("click", function (e) {
	e.preventDefault();
	window.invokeNative("openUrl", e.target.href);
});

var themeMap = {
	orange:  { main: "255, 150, 0",    img: "orange.jpg" },
	red:     { main: "255, 0, 0",      img: "red.jpg" },
	blue:    { main: "0, 163, 255",    img: "blue.jpg" },
	green:   { main: "65, 255, 0",     img: "green.jpg" },
	pink:    { main: "255, 122, 237",  img: "pink.jpg" },
	purple:  { main: "193, 67, 255",   img: "purple.jpg" }
};

if (themeMap[theme]) {
	var t = themeMap[theme];
	$("body").append(`<style>:root{--main:${t.main};}</style>`);
	$("body").css("background-image", `url('assets/img/${t.img}')`);
	$(".winter").css("background", `linear-gradient(0deg, rgb(${t.main} / 10%) 0%, rgba(${t.main}, 0.0) 100%)`);
}

if (enableWinterUpdate) {
	particlesJS("particles-js", { "particles": { "number": { "value": 160, "density": { "enable": true, "value_area": 800 } }, "color": { "value": "#ffffff" }, "shape": { "type": "circle", "stroke": { "width": 0, "color": "#000000" }, "polygon": { "nb_sides": 5 }, "image": { "src": "img/github.svg", "width": 100, "height": 100 } }, "opacity": { "value": 0.5, "random": false, "anim": { "enable": false, "speed": 1, "opacity_min": 0.1, "sync": false } }, "size": { "value": 3, "random": true, "anim": { "enable": false, "speed": 40, "size_min": 0.1, "sync": false } }, "line_linked": { "enable": false, "distance": 150, "color": "#ffffff", "opacity": 0.4, "width": 1 }, "move": { "enable": true, "speed": 1.5, "direction": "bottom", "random": true, "straight": false, "out_mode": "out", "bounce": false, "attract": { "enable": true, "rotateX": 100, "rotateY": 1200 } } }, "interactivity": { "detect_on": "canvas", "events": { "onhover": { "enable": false, "mode": "repulse" }, "onclick": { "enable": false, "mode": "repulse" }, "resize": true }, "modes": { "grab": { "distance": 400, "line_linked": { "opacity": 1 } }, "bubble": { "distance": 400, "size": 40, "duration": 2, "opacity": 8, "speed": 3 }, "repulse": { "distance": 223.7762237762238, "duration": 0.4 }, "push": { "particles_nb": 4 }, "remove": { "particles_nb": 2 } } }, "retina_detect": true });
	$("body").css("background-image", "url('assets/img/winter.jpg')");
	$(".winter").css("display", "flex");
	$("#particles-js").css("opacity", 1);
}

let a, vl, yt, isMute = false, isPaused = false;
var defaultVol = (musicConfig.defaultVolume || 100) / 100;

if (youtubeVideo.startsWith("https://www.youtube.com") && !enableLocalVideo) {
	let videoId = youtubeVideo.split("/").pop().split("=")[1];
	if (!showYoutubeVideo) {
		videoOpacity = 0;
	}
	$("iframe").attr("src", `https://www.youtube.com/embed/${videoId}?autoplay=1&controls=0&enablejsapi=1&disablekb=1`)
		.css({ filter: `blur(${videoBlur}px)`, opacity: videoOpacity });
	if (showYoutubeVideo) $("body").css("background", "#000");
}

if (localAudio) {
	$("body").append('<audio id="audioPlayer" src="audio.mp3" loop></audio>');
	$("#audioPlayer")[0].volume = defaultVol;
	$("#audioPlayer")[0].play();
	a = $("#audioPlayer");
}

if (enableLocalVideo) {
	$("body").css("background", "#000");

	function spawnVideo() {
		$("#videoPlayer").remove();
		var el = document.createElement("video");
		el.id = "videoPlayer";
		el.autoplay = true;
		el.muted = localAudio ? true : false;
		el.setAttribute("playsinline", "");
		el.volume = defaultVol;
		el.src = "video.webm?" + Date.now();

		// Loop dengan reload elemen (bukan seek) — CEF sering gagal seek-balik
		// ke frame 0 pada WebM, jadi elemen dibuat ulang tiap video selesai.
		el.addEventListener("ended", spawnVideo);

		var lastTime = 0;
		var stalledCount = 0;
		el._watch = setInterval(function () {
			if (el.readyState < 2) return;
			var dur = el.duration;
			if (isFinite(dur) && dur > 0 && el.currentTime >= dur - 0.3) {
				clearInterval(el._watch);
				spawnVideo();
				return;
			}
			if (!el.paused) {
				if (el.currentTime <= lastTime) {
					if (++stalledCount >= 4) {
						clearInterval(el._watch);
						spawnVideo();
						return;
					}
				} else {
					stalledCount = 0;
				}
				lastTime = el.currentTime;
			}
		}, 250);

		document.body.appendChild(el);
		el.play().catch(() => {});
		vl = $(el);
	}

	spawnVideo();
}

function onYouTubeIframeAPIReady() {
	yt = new YT.Player("youtube-video", {
		events: { onReady: onPlayerReady }
	});
}

function onPlayerReady() {
	if (localAudio) {
		yt.mute();
	}
}

function toggleMute(self) {
	$(self).toggleClass("act");
	isMute = !isMute;
	if (yt && typeof yt.mute === "function") {
		localAudio ? yt.mute() : (isMute ? yt.mute() : yt.unMute());
	}
	if (a && a[0]) a[0].muted = isMute;
	if (vl && vl[0]) vl[0].muted = localAudio || isMute;

	if (isMute) {
		$(".music-player .mute-btn i").removeClass("bi-volume-up").addClass("bi-volume-mute");
	} else {
		$(".music-player .mute-btn i").removeClass("bi-volume-mute").addClass("bi-volume-up");
	}
}

function togglePause(self) {
	$(self).toggleClass("act");
	isPaused = !isPaused;
	if (yt && typeof yt.pauseVideo === "function" && typeof yt.playVideo === "function") {
		isPaused ? yt.pauseVideo() : yt.playVideo();
	}
	if (a && a[0]) isPaused ? a[0].pause() : a[0].play();
	if (vl && vl[0]) isPaused ? vl[0].pause() : vl[0].play();

	if (isPaused) {
		$(".music-player .play-pause i").removeClass("bi-pause-fill").addClass("bi-play-fill");
	} else {
		$(".music-player .play-pause i").removeClass("bi-play-fill").addClass("bi-pause-fill");
	}
}

function toggleMusicPause() {
	isPaused = !isPaused;
	if (a && a[0]) isPaused ? a[0].pause() : a[0].play();
	if (vl && vl[0]) isPaused ? vl[0].pause() : vl[0].play();
	if (yt && typeof yt.pauseVideo === "function" && typeof yt.playVideo === "function") {
		isPaused ? yt.pauseVideo() : yt.playVideo();
	}

	if (isPaused) {
		$(".music-player .play-pause i").removeClass("bi-pause-fill").addClass("bi-play-fill");
		$(".music-player").removeClass("playing");
	} else {
		$(".music-player .play-pause i").removeClass("bi-play-fill").addClass("bi-pause-fill");
		$(".music-player").addClass("playing");
	}
}

function toggleMusicMute() {
	isMute = !isMute;
	if (a && a[0]) a[0].muted = isMute;
	if (vl && vl[0]) vl[0].muted = localAudio || isMute;
	if (yt && typeof yt.mute === "function") {
		localAudio ? yt.mute() : (isMute ? yt.mute() : yt.unMute());
	}

	if (isMute) {
		$(".music-player .mute-btn i").removeClass("bi-volume-up").addClass("bi-volume-mute");
	} else {
		$(".music-player .mute-btn i").removeClass("bi-volume-mute").addClass("bi-volume-up");
	}
}

function setVolume(volume) {
	if (a && a[0]) a[0].volume = volume / 100;
	if (vl && vl[0]) vl[0].volume = volume / 100;
	if (yt && typeof yt.setVolume === "function" && yt.videoTitle !== "" && !localAudio) {
		yt.setVolume(volume);
	}

	$(".inpt span").text(volume + "%");
	$(".volume-slider").css({
		background: `rgba(var(--main), ${(volume / 100) + 0.2})`
	});

	$(".music-player .volume-text").text(volume + "%");
	$(".music-player .music-volume-slider").val(volume);
}

function setMusicVolume(volume) {
	if (a && a[0]) a[0].volume = volume / 100;
	if (vl && vl[0]) vl[0].volume = volume / 100;
	if (yt && typeof yt.setVolume === "function" && yt.videoTitle !== "" && !localAudio) {
		yt.setVolume(volume);
	}

	$(".music-player .volume-text").text(volume + "%");
	$(".music-player .music-volume-slider").css({
		background: `linear-gradient(to right, rgba(var(--main), 1) 0%, rgba(var(--main), 1) ${volume}%, #353535a6 ${volume}%, #353535a6 100%)`
	});
}

let currentTipIndex = 0;
let progressStartTime = 0;
let progressTimeout;
let paused = false;
let remaining = 0;

function load_tips(config) {
	const container = document.getElementById("tipsContainer");
	const dotsContainer = document.getElementById("dotsContainer");
	container.innerHTML = "";
	dotsContainer.innerHTML = "";

	config.forEach(function (tip, i) {
		const panelItem = document.createElement("div");
		panelItem.classList.add("panelItem");
		panelItem.style.opacity = 0;

		var img = "";
		if (tip.img && tip.img != "") img = `<img src="${tip.img}">`;
		if (tip.img == "") img = `<img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=">`;
		if (tip.img && tip.img.startsWith("/tips")) img = `<img src="assets/img${tip.img}">`;

		panelItem.innerHTML = `
			${img}
			<div class="bg">
				<div class="content">
					<h2>${tip.title}</h2>
					<p>${tip.text}</p>
				</div>
			</div>
		`;
		container.appendChild(panelItem);

		const dot = document.createElement("span");
		dot.classList.add("dot");
		dot.addEventListener("click", function () { showTip(i); });
		panelItem.addEventListener("mouseenter", pauseProgress);
		panelItem.addEventListener("mouseleave", resumeProgress);
		dotsContainer.appendChild(dot);
	});

	showTip(0);
}

function showTip(index) {
	const items = document.querySelectorAll(".panelItem");
	const dots = document.querySelectorAll(".dot");

	items.forEach(function (item, i) {
		if (i === index) {
			fadeIn(item, 100);
			item.classList.add("active");
		} else {
			fadeOut(item, 100);
			item.classList.remove("active");
		}
	});

	dots.forEach(function (dot, i) { dot.classList.toggle("active", i === index); });

	currentTipIndex = index;
	remaining = tipsConfig[index].timeout * 1000;
	startProgress();
}

function fadeIn(element, duration) {
	element.style.display = "";
	element.style.opacity = 0;
	let last = +new Date();
	const tick = function () {
		element.style.opacity = +element.style.opacity + (new Date() - last) / duration;
		last = +new Date();
		if (+element.style.opacity < 1) {
			requestAnimationFrame(tick);
		} else {
			element.style.opacity = 1;
		}
	};
	tick();
}

function fadeOut(element, duration) {
	element.style.opacity = 1;
	let last = +new Date();
	const tick = function () {
		element.style.opacity = +element.style.opacity - (new Date() - last) / duration;
		last = +new Date();
		if (+element.style.opacity > 0) {
			requestAnimationFrame(tick);
		} else {
			element.style.opacity = 0;
			element.style.display = "none";
		}
	};
	tick();
}

function startProgress() {
	const bar = document.getElementById("progressBar");
	const tip = tipsConfig[currentTipIndex];
	const total = remaining;

	clearTimeout(progressTimeout);
	bar.style.transition = "none";
	bar.style.width = `${((tip.timeout * 1000 - remaining) / (tip.timeout * 1000)) * 100}%`;

	progressStartTime = Date.now();

	setTimeout(function () {
		if (!paused) {
			bar.style.transition = `width ${total / 1000}s linear`;
			bar.style.width = "100%";
		}
	}, 20);

	progressTimeout = setTimeout(nextTip, total);
}

function nextTip() {
	remaining = 0;
	showTip((currentTipIndex + 1) % tipsConfig.length);
}

function pauseProgress() {
	if (paused) return;
	paused = true;

	const bar = document.getElementById("progressBar");
	const tip = tipsConfig[currentTipIndex];
	const elapsed = Date.now() - progressStartTime;
	remaining = Math.max(remaining - elapsed, 0);

	const computedWidth = ((tip.timeout * 1000 - remaining) / (tip.timeout * 1000)) * 100;
	bar.style.transition = "none";
	bar.style.width = `${computedWidth}%`;

	clearTimeout(progressTimeout);
}

function resumeProgress() {
	if (!paused) return;
	paused = false;
	startProgress();
}

load_tips(tipsConfig);

if (musicConfig.enabled && musicConfig.showMusicPlayer) {
	$(".music-player").addClass("playing");
	setMusicVolume(musicConfig.defaultVolume || 100);
}