# Quick Paste
#### Manage you frequently copied items for easy access. 
 
## Current
1. copy history
2. url scheme support
3. filter history by name
4. record screenshot copy
5. shortcut paste top 6 record
6. delete single record
7. show either image or text
8. shortcut launch 
9. copy when return on focus item
10. clear all
11. detail view of text and screenshot

## To Do
- [x] key binding, menu seperator 
- [x] support file
- [x] fix custom url scheme crash
- [x] clean file representation
- [x] binded item searchable
- [x] file icon 
- [x] click outside window hide 
- [x] onPasteboardChange() catch all the copy activity
- [x] table should update automatically after persistent container update
- [x] support in-app naive search 
- [x] entry on select could be copied(reuse copyIt)
- [x] retrieve object based on tableview.index, especially when after apply search(filtered history row index has nothing to do with id, temp copied array)
- [ ] move clear and quit to menubar
- [ ] show six record
- [ ] align image in middle
- [ ] resize menu to show at least six items
- [ ] fix file display

## Project Structure
- [x] naive refactor ViewController
- [x] use core data managed object and corresponding class(currently no subclass)
- [x] show history in popover and table instead of status bar menu
## Feature
- [x] remove copied activity record from history
- [x] record screenshot stored to clipboard.(Default is cmd+shift+3+ctrl and cmd+shift+4+ctrl) 
- [x] local shortcut paste using cmd+1~6
- [x] show detail preview on side
## Issue
- [x] avoid save most recent copied since last close, which end up duplicate search history. (use property firstTime check)
- [x] copy it should not add new record, avoid this type of changeCount being trigger (set lastChangeCount same to changeCount)
- [x] right after insert new history record click the history, not the same history record when paste it.(after each update, the tableview should be consistent with copieds)
- [x] if text copied, even default image is set to so icon, but the image won't showup until certain type of searching being performed or relaunch(a real old bug)
- [x] funk sound when hit global shortcut 
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
17. Show either image or text, not both.
18. Dynamic height of text
19. shortcut launch
20. copy when return on focus item
21. clear all record
22. source placeholder
23. separate data source and tableView delegate from viewcontroller
24. enhance focus behavior(focus on same record when reopen popover & focus remain nearby after deletion)
25. little visual improvement(enlarge visual assets, exchange column order)
26. set up splitview(view present)
27. connecet between viewcontroller and detailViewController
28. fix deletion crash after connecting(27)
29. fix copyOnEnter without menu showing up
30. showing content in detailViewController
31. mute funk sound
## Inspiration (Why yet another pasteboard manager)
Copy paste repeatedly is tedious. It's even less interesting when you forget what you copy. 
Paid pasteboard manager app provide really complicated use scenario, which I barely used. Among all the open source alternatives, none of them support screenshot, which heavily involved in my daily documentation and note-taking. 