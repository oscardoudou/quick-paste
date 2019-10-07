# Quick Paste
#### Manage you frequently used item for easy access. 
## Inspiration
Initially it is just a simple tool to facilate my job application filling process. When I do job hunting, my mac was slow. Opening too many app(Adobe Reader, MS Word and too much safari chrome tab) significantly slow my mac. Also copy paste repeatedly is tedious. So I came to the idea to store frequently copied item in menu bar.  

## Current Phase
1. The initial purpose resume parsing, menu would look good only in this [resume](https://www.dropbox.com/s/8r6wm7d8t45pmsc/2019_Resume_Yichi_Zhang.pdf?dl=0) format. 
2. Key equavilant support from 1 to 9
3. Support custom url scheme, run `open "readlog://textwanttosend"`in terminal would copy the text to menu. 
4. Support local file and folder
5. Log copy from mac and ios devices
6. Support search binded item in spotlight
7. Show file icon in menu(not that useful since most file has extension shown, mainly for further image related feature)
## To Do(small or priority)
- [x] key binding, menu seperator 
- [x] support file
- [x] fix custom url scheme crash
- [x] clean file representation
- [x] binded item searchable
- [x] file icon 
- [ ] split file if necessary
- [ ] use core data managed object and corresponding class(currently no subclass demand) 
- [ ] restrict menu size
- [ ] duplicate check
## Feature
- [ ] spotlight on tap redirect(work for some file like pdf, zip and doc, need further test but definitely need implement continued activity function)
- [ ] remove item from menu bar 
## Issue
- [ ] copy event searchable(only work for text, seems like a tough issue)
- [ ] copy event searchable(if bind it later, would result two searchableItem)
- [ ] spotlight thumbnail(only work for part of the file extension, even same extension not all able to quick look)
- [ ] resized icon should fit retina sceen
 A lot to do.
