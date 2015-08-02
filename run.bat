@echo on
net start MongoDB
forever --minUptime 1000 --spinSleepTime 1000 -w .\lib\app.js 