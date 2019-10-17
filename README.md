# Quick Paste
#### Manage you frequently used item for easy access. 
## Inspiration
Initially it is just a simple tool to facilate my job application filling process. When I do job hunting, my mac was slow. Opening too many app(Adobe Reader, MS Word and too much safari chrome tab) significantly slow my mac. Also copy paste repeatedly is tedious. So I came to the idea to store frequently copied item in menu bar.  
## Current
1. copy history
2. url scheme support
3. filter history by name
4. record screenshot copy
5. shortcut paste top 6 record
## To Do
- [x] key binding, menu seperator 
- [x] support file
- [x] fix custom url scheme crash
- [x] clean file representation
- [x] binded item searchable
- [x] file icon 
- [ ] duplicate check
- [ ] click outside window hide 
- [x] onPasteboardChange() catch all the copy activity
- [x] table should update automatically after persistent container update
- [x] support in-app naive search 
- [x] entry on select could be copied(reuse copyIt)
- [x] retrieve object based on tableview.index, especially when after apply search(filtered history row index has nothing to do with id, temp copied array)
## Project Structure
- [x] split file if necessary
- [x] use core data managed object and corresponding class(currently no subclass)
- [x] show history in popover and table instead of status bar menu
## Feature
- [ ] spotlight on tap redirect(work for some file like pdf, zip and doc, need further test but definitely need implement continued activity function)
- [ ] remove copied activity record from history
- [x] record screenshot stored to clipboard.(Default is cmd+shift+3+ctrl and cmd+shift+4+ctrl) 
- [x] local shortcut paste using cmd+1~6
## Issue
- [ ] copy event searchable(only work for text, seems like a tough issue)
- [ ] copy event searchable(if bind it later, would result two searchableItem, currently disbale copy event searchable)
- [ ] spotlight thumbnail(only work for part of the file extension, even same extension would differ)
- [ ] resized icon should fit retina display
- [x] avoid save most recent copied since last close, which end up duplicate search history. (use property firstTime check)
- [x] copy it should not add new record, avoid this type of changeCount being trigger (set lastChangeCount same to changeCount)
- [x] right after insert new history record click the history, not the same history record when paste it.(after each update, the tableview should be consistent with copieds)
## Dev history
1. The initial purpose resume parsing, menu would look good only in this [resume](https://www.dropbox.com/s/8r6wm7d8t45pmsc/2019_Resume_Yichi_Zhang.pdf?dl=0) format. 
2. Key equavilant support from 1 to 9
3. Support custom url scheme, run `open "readlog://textwanttosend"`in terminal would copy the text to menu. 
4. Support local file and folder
5. Log copy from mac and ios devices
6. Support search binded item in spotlight
7. Show file icon in menu(not that useful since most file has extension shown, mainly for further image related feature)
8. Add data controller which working with core data persistent container to memorize previous history after relaunch app
9. Use popover and table view instead of status bar menu for furtuher layout customization
10. Use NSFetchedResultsController along with NSTableViewDelegate and NSTableViewDataSource showing data in table view 
11. Able to track most copy activities
12. Change copy->bindIt(create object) logic to copy(automatically create object)
13. Support naive search in search field with NSSearchFieldDelegate(predicate update, fetch and reload)
14. On click copy to pasteboard
15. Record screenshots directly into clipboard
16. Support local shortcut paste top 6 shown item
