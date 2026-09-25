const PASS_THRESHOLDS = {
    police: 9,      
    ambulance: 9,   
    gang: 10,       
    mechanic: 9,    
    civilian: 8     
};

let currentJob = "";
let currentQuestions = [];
let currentQuestionIndex = 0;
let userAnswers = [];

const allQuestions = {
    police: [
        { q: "What is the primary responsibility of a police officer in an RP server?", options: ["A. Arrest as many players as possible", "B. Win every gunfight", "C. Maintain law and order while creating fair and enjoyable RP", "D. Protect other police officers at all costs"], a: 2 },
        { q: "What does 'Roleplay Over Gunplay' mean?", options: ["A. Police should never use firearms", "B. RP situations should be prioritized over unnecessary shooting", "C. Police should always surrender", "D. Gunfights are not allowed"], a: 1 },
        { q: "A suspect is insulting you during an arrest. What should you do?", options: ["A. Insult them back", "B. Shoot them", "C. Remain professional and continue the RP", "D. Arrest them for disrespect"], a: 2 },
        { q: "You see another officer breaking server rules. What should you do?", options: ["A. Ignore it because they're an officer", "B. Join them", "C. Handle/report it through the proper staff or department process", "D. Publicly shame them"], a: 2 },
        { q: "When should an officer use their firearm?", options: ["A. Whenever a suspect runs away", "B. Whenever someone insults them", "C. When there is a legitimate RP situation that justifies lethal force", "D. Whenever they feel threatened"], a: 2 },
        { q: "A vehicle refuses to stop during a traffic stop and begins fleeing. What should you do?", options: ["A. Immediately shoot the vehicle", "B. Initiate an appropriate pursuit and communicate with other units", "C. Ignore the vehicle", "D. Ram the vehicle repeatedly"], a: 1 },
        { q: "During a pursuit, you lose visual contact with the suspect. What should you do?", options: ["A. Randomly arrest someone nearby", "B. Continue communicating the last known location and search appropriately", "C. Shoot every vehicle matching the description", "D. Leave the server"], a: 1 },
        { q: "You arrive at a robbery with hostages. What should be your first priority?", options: ["A. Immediately storm the building", "B. Start shooting", "C. Secure the scene and establish communication/control", "D. Arrest everyone nearby"], a: 2 },
        { q: "What is metagaming?", options: ["A. Using information obtained through RP", "B. Using information obtained outside RP to influence your character's actions", "C. Talking to other officers", "D. Using police equipment"], a: 1 },
        { q: "Which is an example of metagaming?", options: ["A. Hearing a suspect's location through police radio", "B. Seeing a suspect commit a crime", "C. Watching the suspect's Discord stream and using their location in-game", "D. Receiving information from another officer in-game"], a: 2 },
        { q: "What is powergaming?", options: ["A. Using excessive force or forcing an RP outcome without giving another player a reasonable opportunity to respond", "B. Using police equipment", "C. Calling backup", "D. Driving a police vehicle"], a: 0 },
        { q: "A suspect has surrendered and is cooperating. What should you do?", options: ["A. Continue shooting them", "B. Maintain control of the situation and proceed with the arrest", "C. Immediately execute them", "D. Let them go because they're cooperating"], a: 1 },
        { q: "A fellow officer tells you to arrest someone, but you have no evidence or reasonable RP basis to do so. What should you do?", options: ["A. Arrest them anyway", "B. Ask for the reason/basis and follow proper procedure", "C. Shoot the civilian", "D. Ignore all police procedures"], a: 1 },
        { q: "You're outnumbered during a dangerous situation. What should you generally do?", options: ["A. Rush in alone", "B. Request backup and manage the situation appropriately", "C. Immediately shoot everyone", "D. Disconnect"], a: 1 },
        { q: "A civilian claims that a police officer abused their power. What should you do?", options: ["A. Threaten the civilian", "B. Ignore the complaint", "C. Follow the appropriate complaint/investigation process", "D. Arrest the civilian for complaining"], a: 2 },
        { q: "You make a mistake during an RP situation. What should you do?", options: ["A. Pretend it never happened", "B. Escalate the situation", "C. Acknowledge the mistake and handle it appropriately", "D. Blame another player"], a: 2 },
        { q: "Your friend is being arrested by another officer. What should you do?", options: ["A. Immediately interfere because they're your friend", "B. Use your position to release them", "C. Remain professional and allow the situation to proceed properly", "D. Threaten the arresting officer"], a: 2 },
        { q: "You are off-duty and witness a crime. What should you do?", options: ["A. Automatically use all police powers", "B. Follow your server's off-duty rules and only intervene where permitted", "C. Start a police pursuit", "D. Arrest everyone involved"], a: 1 },
        { q: "A high-ranking officer orders you to violate a server rule. What should you do?", options: ["A. Follow the order because they're higher rank", "B. Refuse to participate in the rule violation and report/escalate it appropriately", "C. Follow the order and delete the evidence", "D. Quit the department immediately"], a: 1 },
        { q: "Why should you become a police officer?", options: ["A. To get better weapons", "B. To have authority over civilians", "C. To create enjoyable RP, enforce rules fairly, and contribute positively to the community", "D. To win more gunfights"], a: 2 }
    ],
    ambulance: [
        { q: "What is the primary role of an EMS/Paramedic in the city?", options: ["A. Arrest criminals", "B. Provide medical assistance and create quality medical RP", "C. Participate in police shootouts", "D. Protect police officers"], a: 1 },
        { q: "A civilian is critically injured after a shootout. What should you prioritize?", options: ["A. Ask who started the shootout", "B. Immediately revive them without RP", "C. Secure the scene and assess the patient's condition", "D. Arrest the injured person"], a: 2 },
        { q: "You arrive at a scene where gunfire is still happening. What should you do?", options: ["A. Run directly toward the injured person", "B. Secure the area or wait until police confirm it is safe", "C. Start shooting the suspects", "D. Leave without telling anyone"], a: 1 },
        { q: "What is the main purpose of medical RP?", options: ["A. To instantly revive players", "B. To provide realistic and enjoyable medical roleplay", "C. To avoid interacting with players", "D. To give EMS authority over civilians"], a: 1 },
        { q: "A patient is unconscious. What should an EMS member do?", options: ["A. Immediately type /revive", "B. Perform appropriate medical RP and assess the patient", "C. Leave them because they cannot talk", "D. Ask them to respawn"], a: 1 },
        { q: "A patient is refusing medical treatment. What should you generally do?", options: ["A. Force treatment immediately", "B. Respect the refusal unless server rules/protocol provide otherwise", "C. Arrest them", "D. Ignore all RP"], a: 1 },
        { q: "A police officer asks you to prioritize an injured suspect over another patient who is in more critical condition. What should you do?", options: ["A. Treat the suspect because police requested it", "B. Treat patients based on medical urgency and department procedures", "C. Ignore both patients", "D. Let the police decide who gets treated"], a: 1 },
        { q: "What should you do when arriving at a major accident scene?", options: ["A. Immediately start treating the first person you see", "B. Assess the scene and identify the most urgent medical needs", "C. Leave because there are too many patients", "D. Revive everyone simultaneously"], a: 1 },
        { q: "What is an appropriate reason to use an ambulance's siren and emergency lights?", options: ["A. To get through traffic faster whenever you want", "B. When responding to an emergency or transporting a patient according to server rules", "C. To intimidate civilians", "D. To race other vehicles"], a: 1 },
        { q: "You're transporting a critically injured patient and police request that you stop. What should you do?", options: ["A. Ignore police completely", "B. Communicate with police and follow appropriate emergency procedures", "C. Abandon the patient", "D. Drive away from the city"], a: 1 },
        { q: "A patient begins insulting you while you are treating them. How should you respond?", options: ["A. Insult them back", "B. Refuse to treat everyone at the scene", "C. Remain professional and continue the RP", "D. Arrest them"], a: 2 },
        { q: "You see another EMS member intentionally breaking server rules. What should you do?", options: ["A. Join them", "B. Ignore it because they're EMS", "C. Report it through the proper department/staff process", "D. Publicly argue with them"], a: 2 },
        { q: "What is metagaming in EMS RP?", options: ["A. Using medical equipment", "B. Using information obtained outside the game to influence your character's actions", "C. Talking to police", "D. Using the ambulance radio"], a: 1 },
        { q: "Which is an example of metagaming?", options: ["A. A police officer tells you in-game that someone is injured", "B. You receive a dispatch call", "C. You see an injured player yourself", "D. You watch a player's Discord stream and use their location to find them"], a: 3 },
        { q: "What should an EMS member do when they are dispatched to a scene?", options: ["A. Ignore dispatch", "B. Acknowledge the call and respond appropriately", "C. Wait for another EMS member to do it every time", "D. Go to random locations instead"], a: 1 },
        { q: "You arrive at a scene where another EMS member is already treating the patient. What should you do?", options: ["A. Take over immediately", "B. Ask how you can assist and coordinate with them", "C. Leave immediately", "D. Start treating a different patient without communicating"], a: 1 },
        { q: "A patient asks you to revive their friend even though the friend is not actually incapacitated. What should you do?", options: ["A. Revive them anyway", "B. Follow proper medical RP and server procedures", "C. Give them medical equipment", "D. Ignore all rules"], a: 1 },
        { q: "Why is communication important for EMS?", options: ["A. It allows EMS to coordinate responses and provide better RP", "B. It allows EMS to control police", "C. It makes EMS more powerful", "D. It is only necessary during shootouts"], a: 0 },
        { q: "An EMS member is being pressured by a criminal to treat someone while police are actively clearing a dangerous scene. What should the EMS member do?", options: ["A. Enter immediately", "B. Prioritize their safety and wait until the scene is safe", "C. Fight the criminals", "D. Ignore police instructions"], a: 1 },
        { q: "Why do you want to become an EMS member?", options: ["A. To get access to an ambulance", "B. To have authority over civilians", "C. To provide medical RP, help players, and contribute positively to the city", "D. To avoid playing as a civilian"], a: 2 }
    ],
    gang: [
        { q: "What is the primary purpose of joining a gang in an RP server?", options: ["A. To get better weapons", "B. To dominate other players", "C. To create meaningful gang RP, interactions, and storylines", "D. To kill civilians"], a: 2 },
        { q: "Which statement best describes the server's position on cheating?", options: ["A. Cheating is allowed during gang wars", "B. Cheating is allowed if nobody notices", "C. Cheating is strictly prohibited under all circumstances", "D. Cheating is acceptable during competitive situations"], a: 2 },
        { q: "You discover a third-party cheat that gives you an advantage over other players. What should you do?", options: ["A. Use it only during gang wars", "B. Use it secretly", "C. Do not use it and report the issue if appropriate", "D. Let your gang members use it"], a: 2 },
        { q: "What is RDM (Random Deathmatch)?", options: ["A. Killing someone with a valid RP reason", "B. Killing another player without a valid RP reason or proper RP initiation", "C. Defending yourself during an active RP situation", "D. A scheduled gang war"], a: 1 },
        { q: "Your gang member tells you to shoot a random civilian because they 'look suspicious.' What should you do?", options: ["A. Shoot them immediately", "B. Ask for proper RP justification and avoid RDM", "C. Shoot them if nobody is watching", "D. Kill them and leave the area"], a: 1 },
        { q: "Which of the following is considered RDM?", options: ["A. Shooting someone during an established RP conflict", "B. Defending yourself from an active threat", "C. Randomly shooting a player with no RP justification", "D. Participating in an approved gang scenario"], a: 2 },
        { q: "What is Fail RP?", options: ["A. Losing a gunfight", "B. Failing to follow the server's roleplay standards or acting unrealistically in an RP situation", "C. Getting arrested", "D. Losing a gang territory"], a: 1 },
        { q: "You are seriously injured after being hit by a vehicle. What should you do?", options: ["A. Immediately stand up and sprint away", "B. Continue roleplaying the injury appropriately", "C. Pull out a weapon and fight immediately", "D. Pretend nothing happened"], a: 1 },
        { q: "Your gang loses a gunfight. What is the proper response?", options: ["A. Respawn and immediately return for revenge", "B. Use outside information to locate the enemy", "C. Continue RP and follow the server's rules regarding death/respawning", "D. Disconnect to avoid the consequences"], a: 2 },
        { q: "Your friend tells you through Discord where an enemy gang member is hiding. What should you do?", options: ["A. Go directly to that location", "B. Use the information because your friend is in your gang", "C. Do not use information obtained outside RP", "D. Tell everyone in your gang"], a: 2 },
        { q: "What should you NEVER use to gain an unfair advantage in RP?", options: ["A. Legal weapons available to your character", "B. Gang communication channels permitted by the server", "C. Cheats, exploits, unauthorized software, or other unfair advantages", "D. Vehicles available to your gang"], a: 2 },
        { q: "An enemy gang member insults your gang. Does that automatically give you justification to kill them?", options: ["A. Yes", "B. Yes, if they insult your leader", "C. No, there must be appropriate RP justification according to server rules", "D. Yes, if you're carrying a weapon"], a: 2 },
        { q: "Your gang is planning a conflict with another gang. What should you prioritize?", options: ["A. Getting the highest kill count", "B. Creating a fair and enjoyable RP scenario", "C. Using exploits to win", "D. Ambushing random civilians"], a: 1 },
        { q: "You are losing a fight and decide to intentionally disconnect from the server. What is this?", options: ["A. Good strategy", "B. Proper RP", "C. An attempt to avoid RP/consequences and potentially a server-rule violation", "D. Tactical retreat"], a: 2 },
        { q: "A gang member tells you to use a cheat because 'everyone else is cheating.' What should you do?", options: ["A. Use it temporarily", "B. Use it only when outnumbered", "C. Refuse and report the behavior through the appropriate process", "D. Ask them which cheat they use"], a: 2 },
        { q: "You see a gang member committing RDM. What should you do?", options: ["A. Help them kill more players", "B. Ignore it because they're your gang member", "C. Stop participating in the behavior and report/escalate it appropriately", "D. Record it and post it publicly to embarrass them"], a: 2 },
        { q: "Your gang gets attacked unexpectedly. What is the proper approach?", options: ["A. Immediately RDM everyone in the area", "B. Respond within the RP situation while following server rules", "C. Use cheats to gain an advantage", "D. Bring players from outside the server to help"], a: 1 },
        { q: "Which behavior is most likely to be considered Fail RP?", options: ["A. Negotiating with another gang", "B. Roleplaying fear when held at gunpoint", "C. Treating serious injuries as if nothing happened", "D. Retreating from a dangerous situation"], a: 2 },
        { q: "What should a gang leader do if their members repeatedly violate rules such as cheating, RDM, or Fail RP?", options: ["A. Protect them because they are gang members", "B. Encourage them if they help the gang win", "C. Address the behavior and cooperate with management/staff when necessary", "D. Hide the violations"], a: 2 },
        { q: "What do you agree to when joining a gang on this server?", options: ["A. Winning is more important than RP", "B. Gang members are allowed to RDM and Fail RP during conflicts", "C. I will follow the server rules, especially the strict prohibition against cheating, RDM, and Fail RP, while contributing to quality RP", "D. I can break rules if another gang starts first"], a: 2 }
    ],
    mechanic: [
        { q: "What is the primary role of a mechanic in an RP server?", options: ["A. Participate in gang activities", "B. Repair, maintain, and provide quality automotive RP for citizens", "C. Help police arrest criminals", "D. Race other players"], a: 1 },
        { q: "A customer arrives at the mechanic shop asking for a repair. What should you do?", options: ["A. Immediately repair the vehicle without RP", "B. Roleplay inspecting the vehicle and communicate with the customer", "C. Ignore the customer", "D. Ask them to repair it themselves"], a: 1 },
        { q: "Why is roleplay important when working as a mechanic?", options: ["A. It makes repairs take longer", "B. It creates a more immersive and enjoyable experience for everyone", "C. It prevents mechanics from making money", "D. It is only necessary when police are present"], a: 1 },
        { q: "A customer becomes angry because their repair is taking too long. What should you do?", options: ["A. Argue with them", "B. Refuse to serve them", "C. Remain professional and continue the RP appropriately", "D. Damage their vehicle"], a: 2 },
        { q: "A customer offers you extra money to repair their vehicle ahead of everyone else. What should you do?", options: ["A. Always accept", "B. Follow your department/server procedures regarding priority and payment", "C. Repair their vehicle secretly", "D. Kick everyone else out"], a: 1 },
        { q: "You are repairing a vehicle when the owner suddenly drives away. What should you do?", options: ["A. Shoot at the vehicle", "B. Chase and ram them", "C. Handle the situation through appropriate RP and report any issue if necessary", "D. Spawn another vehicle"], a: 2 },
        { q: "A customer asks you to intentionally damage another player's vehicle. What should you do?", options: ["A. Accept because they are paying", "B. Do it if nobody is watching", "C. Refuse and avoid participating in malicious or rule-breaking RP", "D. Ask for more money"], a: 2 },
        { q: "What should a mechanic do if a vehicle arrives with visible damage?", options: ["A. Pretend the damage doesn't exist", "B. RP an inspection and determine the appropriate repair", "C. Immediately replace the entire vehicle", "D. Destroy the vehicle"], a: 1 },
        { q: "You discover another mechanic is abusing their job permissions. What should you do?", options: ["A. Ignore it", "B. Join them", "C. Report it through the appropriate department/staff process", "D. Threaten them"], a: 2 },
        { q: "What is Fail RP?", options: ["A. Having your vehicle break down", "B. Acting in a way that ignores reasonable roleplay or server rules", "C. Losing a race", "D. Charging a customer"], a: 1 },
        { q: "Which is an example of Fail RP for a mechanic?", options: ["A. Roleplaying a tire replacement", "B. Inspecting an engine", "C. Repairing a severely damaged vehicle instantly without any RP when RP is expected", "D. Explaining a repair to a customer"], a: 2 },
        { q: "What is RDM?", options: ["A. Randomly repairing vehicles", "B. Randomly killing another player without proper RP justification", "C. Driving recklessly", "D. Refusing a repair"], a: 1 },
        { q: "A customer refuses to pay after receiving a legitimate repair. What should you do?", options: ["A. Shoot them", "B. Chase them and ram their vehicle", "C. Handle it through appropriate RP and department/server procedures", "D. Use your mechanic job to disable their vehicle"], a: 2 },
        { q: "Can a mechanic use their job position as an excuse to participate in RDM or other rule violations?", options: ["A. Yes", "B. Only against criminals", "C. Only when off-duty", "D. No, mechanics must follow the same server rules as everyone else"], a: 3 },
        { q: "You discover a bug that allows mechanics to duplicate items or make unlimited money. What should you do?", options: ["A. Use it before it gets fixed", "B. Share it with your friends", "C. Report the exploit and avoid abusing it", "D. Sell the information to other players"], a: 2 },
        { q: "What is cheating?", options: ["A. Using legitimate mechanic tools", "B. Using unauthorized software, cheats, or other methods to gain an unfair advantage", "C. Repairing vehicles", "D. Upgrading a vehicle"], a: 1 },
        { q: "A friend asks you to use your mechanic permissions to give them free upgrades that they normally cannot obtain. What should you do?", options: ["A. Do it because they are your friend", "B. Do it if nobody finds out", "C. Follow the approved mechanic procedures and refuse unauthorized benefits", "D. Give them even more upgrades"], a: 2 },
        { q: "You are called to repair a vehicle at a dangerous scene where gunfire is occurring. What should you do?", options: ["A. Drive directly into the gunfight", "B. Prioritize your safety and wait until the area is reasonably safe", "C. Pull out a weapon and join the fight", "D. Ram the suspects"], a: 1 },
        { q: "What should you do if you are unsure whether an action is allowed under server or mechanic rules?", options: ["A. Do it anyway", "B. Ask a supervisor or staff member before proceeding", "C. Ask another civilian", "D. Find a way around the rule"], a: 1 },
        { q: "What do you agree to when joining the mechanic department?", options: ["A. I can break rules while on duty", "B. I can use my mechanic role to gain personal advantages", "C. I will provide quality RP, treat customers fairly, and strictly follow server rules, including the prohibition of cheating, RDM, and Fail RP", "D. I can abuse my job permissions if I don't get caught"], a: 2 }
    ],
    civilian: [
        { q: "What does RDM mean?", options: ["A. Randomly repairing a vehicle", "B. Random Deathmatch — killing a player without valid RP justification", "C. Running from police", "D. Randomly driving around"], a: 1 },
        { q: "What does VDM mean?", options: ["A. Using a vehicle to intentionally kill or harm another player without proper RP justification", "B. Stealing a vehicle", "C. Driving without a license", "D. Modifying a vehicle"], a: 0 },
        { q: "Which of the following is an example of VDM?", options: ["A. Accidentally hitting someone while driving", "B. Running over a player intentionally because you are angry with them", "C. Parking your vehicle", "D. Racing another player"], a: 1 },
        { q: "What is Fail RP?", options: ["A. Losing an RP situation", "B. Acting in a way that ignores realistic or reasonable roleplay and/or server rules", "C. Getting arrested", "D. Being killed by another player"], a: 1 },
        { q: "You crash your car at high speed and your character immediately gets out and runs away without acknowledging the accident. What could this be?", options: ["A. Good RP", "B. Fail RP", "C. VDM", "D. Metagaming"], a: 1 },
        { q: "What is Metagaming?", options: ["A. Using information your character legitimately learned in-game", "B. Using information obtained outside of RP to influence your character's actions", "C. Talking to another player", "D. Using a map"], a: 1 },
        { q: "Which is an example of Metagaming?", options: ["A. A friend tells you through Discord that they are being robbed, and you use that information to locate and help them in-game", "B. A police officer tells you something through in-game voice", "C. You see a robbery happening yourself", "D. You receive an in-game phone call"], a: 0 },
        { q: "What is Powergaming?", options: ["A. Playing for several hours", "B. Forcing actions or outcomes on another player without giving them a reasonable opportunity to RP", "C. Using a powerful vehicle", "D. Becoming a high-ranking employee"], a: 1 },
        { q: "Which is an example of Powergaming?", options: ["A. Saying /me searches the suspect and allowing them to respond", "B. Saying that you automatically handcuffed, searched, and robbed another player without allowing them to respond", "C. Asking someone to raise their hands", "D. Negotiating with another player"], a: 1 },
        { q: "What is Combat Logging?", options: ["A. Logging into the server during combat", "B. Disconnecting from the server to avoid an active RP situation or its consequences", "C. Changing your weapon", "D. Losing a gunfight"], a: 1 },
        { q: "You are being arrested and disconnect from the server to avoid the arrest. What rule may you have violated?", options: ["A. VDM", "B. RDM", "C. Combat Logging / RP avoidance", "D. Safezone RP"], a: 2 },
        { q: "What is Fear RP?", options: ["A. Being afraid to lose money", "B. Your character reasonably valuing their life when faced with a serious threat", "C. Being scared of the police", "D. Leaving the server because you're scared"], a: 1 },
        { q: "Someone points a gun at you at close range and you have no realistic means of escape. What should you generally do?", options: ["A. Pull out your gun and immediately shoot them every time", "B. Act as though your character recognizes the danger and values their life", "C. Laugh and walk away", "D. Disconnect"], a: 1 },
        { q: "What is NLR (New Life Rule)?", options: ["A. You get a new character every day", "B. After your character dies/respawns, you must follow the server's rules regarding memory of the previous situation and returning to it", "C. You cannot change clothes", "D. You must always play as a civilian"], a: 1 },
        { q: "After being killed during an RP situation, you respawn and immediately return to the location to get revenge. What could this violate?", options: ["A. NLR", "B. VDM", "C. Metagaming only", "D. No rule"], a: 0 },
        { q: "What should you do inside a designated Safezone?", options: ["A. Start fights because nobody can shoot you", "B. Follow the specific Safezone rules and avoid using the area to abuse protection from RP", "C. Rob players because weapons are disabled", "D. Use the Safezone to escape every police pursuit"], a: 1 },
        { q: "You are being chased by police and deliberately enter a Safezone solely to prevent them from continuing the RP. What could this be considered?", options: ["A. Good strategy", "B. Safezone abuse / RP avoidance", "C. VDM", "D. Fear RP"], a: 1 },
        { q: "Which behavior is strictly prohibited on the server?", options: ["A. Creating RP with other players", "B. Participating in legal jobs", "C. Using cheats, exploits, or unauthorized software to gain an advantage", "D. Running from the police during valid RP"], a: 2 },
        { q: "Another player breaks a rule against you. Does that give you permission to break the same rule back?", options: ["A. Yes", "B. Only if they started it", "C. No, you should continue following the rules and report the violation appropriately", "D. Yes, if nobody is recording"], a: 2 },
        { q: "What is the most important principle when playing on the server?", options: ["A. Winning every situation", "B. Getting the most money", "C. Prioritizing quality RP while following all server rules", "D. Having the most kills"], a: 2 }
    ]
};

window.addEventListener('message', function(event) {
    if (event.data.action === "openMenu") {
        document.getElementById('app').style.display = 'flex';
        document.getElementById('job-menu').style.display = 'block';
        document.getElementById('quiz-container').style.display = 'none';
        document.getElementById('result-container').style.display = 'none';
    }
});

function startQuiz(jobId) {
    currentJob = jobId;
    currentQuestionIndex = 0;
    
    document.getElementById('job-menu').style.display = 'none';
    document.getElementById('quiz-container').style.display = 'block';
    document.getElementById('quiz-title').innerText = jobId.charAt(0).toUpperCase() + jobId.slice(1) + " Exam";
    
    let pool = [...allQuestions[jobId]];
    pool = pool.sort(() => 0.5 - Math.random());
    currentQuestions = pool.slice(0, 10);
    userAnswers = new Array(10).fill(null);
    
    renderCurrentQuestion();
}

function renderCurrentQuestion() {
    document.getElementById('error-message').style.display = 'none';
    document.getElementById('question-counter').innerText = `Question ${currentQuestionIndex + 1} of ${currentQuestions.length}`;
    
    const wrapper = document.getElementById('single-question-wrapper');
    const qData = currentQuestions[currentQuestionIndex];
    
    let html = `<h3>${qData.q}</h3>`;
    qData.options.forEach((opt, optIndex) => {
        let isChecked = userAnswers[currentQuestionIndex] === optIndex ? "checked" : "";
        html += `<label class="options-label">
                    <input type="radio" name="q_option" value="${optIndex}" ${isChecked}>
                    ${opt}
                 </label>`;
    });
    wrapper.innerHTML = html;

    if (currentQuestionIndex === currentQuestions.length - 1) {
        document.getElementById('next-btn').style.display = 'none';
        document.getElementById('submit-btn').style.display = 'inline-block';
    } else {
        document.getElementById('next-btn').style.display = 'inline-block';
        document.getElementById('submit-btn').style.display = 'none';
    }
}

function nextQuestion() {
    const selected = document.querySelector(`input[name="q_option"]:checked`);
    if (!selected) {
        document.getElementById('error-message').style.display = 'block';
        return;
    }
    
    userAnswers[currentQuestionIndex] = parseInt(selected.value);
    currentQuestionIndex++;
    renderCurrentQuestion();
}

function submitQuiz() {
    const selected = document.querySelector(`input[name="q_option"]:checked`);
    if (!selected) {
        document.getElementById('error-message').style.display = 'block';
        return;
    }
    
    userAnswers[currentQuestionIndex] = parseInt(selected.value);
    
    let score = 0;
    currentQuestions.forEach((item, index) => {
        if (userAnswers[index] === item.a) {
            score++;
        }
    });

    showResult(score);
}

function showResult(score) {
    document.getElementById('quiz-container').style.display = 'none';
    document.getElementById('result-container').style.display = 'block';
    
    const threshold = PASS_THRESHOLDS[currentJob];
    const resultTitle = document.getElementById('result-title');
    const resultMsg = document.getElementById('result-message');
    const actionBtn = document.getElementById('result-action-btn');

    if (score >= threshold) {
        resultTitle.innerText = "Congratulations!";
        resultTitle.style.color = "#5cb85c";
        resultMsg.innerText = `You passed the exam with a score of ${score}/10!`;
        
        actionBtn.innerText = "Enter City";
        actionBtn.style.background = "#5cb85c";
        actionBtn.onclick = function() {
            document.getElementById('app').style.display = 'none';
            fetch(`https://${GetParentResourceName()}/setPlayerJob`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ job: currentJob })
            });
        };
    } else {
        resultTitle.innerText = "Exam Failed";
        resultTitle.style.color = "#d9534f";
        resultMsg.innerText = `You scored ${score}/10. You need at least ${threshold}/10 to pass.`;
        
        actionBtn.innerText = "Return to Menu";
        actionBtn.style.background = "#d9534f";
        actionBtn.onclick = function() {
            document.getElementById('result-container').style.display = 'none';
            document.getElementById('job-menu').style.display = 'block';
            
            if (currentJob !== 'civilian') {
                const card = document.getElementById(`card-${currentJob}`);
                card.classList.add('disabled');
                card.onclick = null;
            }
        };
    }
}

function goBackToMenu() {
    document.getElementById('quiz-container').style.display = 'none';
    document.getElementById('job-menu').style.display = 'block';
}