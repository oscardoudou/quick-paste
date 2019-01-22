# Quick Paste
Manage you frequently copy paste entries accessible easily from status bar. For me it is just a simple tool to facilate job application filling process, so that you don't need to open your resume, cover letter or copy your Linkedin GitHub link everytime. It becomes especially helpful for me since my macbook is kind of slow after updatin Mojave. Opening Adobe Reader, MS word and pinning safari tab all the time make it even worse. Render response time of pinned tab sometimes is really convenient sometime it just drives you crazy.   
## Current phase
It is really a self-used menu bar tool now, which only support extract title from your resume when you resume title is in the form like this:
```
Full-Stack Web Application for YelpCamp (JavaScript, Node.js, HTML, JQuery)
• Developed a full-stack MVC-structured web application for campground review, with CRUD operations and REST service
• Implemented front-end with Bootstrap, JQuery, CSS animations, and location visualization with Google Maps API
• Implemented back-end with user authentication using Node.js, Express, MongoDB, mLab and deployed through Heroku
```
It extracts the string before parenthesis in the first line. And present it as an entry in status bar with a key equivalent corresponding to its adding order(start from 1).  
## Todo
- [x] extract title when () present in first line
- [x] key binding
- [x] support Linkedin GitHub link(w/ or w/o https://) only show host
- [x] separator item Stackoverflow Linkedin GitHub icon available to show 
- [x] support email
- [ ] content w/o @ . (

