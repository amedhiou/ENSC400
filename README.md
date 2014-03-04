----------------------------------------------------------------------
->This file will contain a list as well as a Description to all the  
  directories in this git repo.                                      
->This file will also have a step by step user guide as well as steps
  to push and pull from it                                           
->This file also contains a template for commit messages that should 
  used from now on                                                   
----------------------------------------------------------------------
=====================================================================
= How to clone, pull and push to ENSC400.git
=====================================================================

* Clone:
	$ git clone https://github.com/amedhiou/ENSC400.git

* pull:
	$ git pull origin master

* push:
 	$ git add <file1> <file2> ...
	$ git commit 
	 	here you should copy the commit message template below and create
	 	your commit message. once you re satisfied with the message save it
		$ :wq
	$ git push origin master

=====================================================================
= commit message Template:
=====================================================================
 
 -Author: Name (prefrably first and last)

 -Date: mm-dd-yyy (the format is not that important)

 -Title : (KISS , informative and sumerizes the general work committed)

 -Description:
	* action 1 ...
	* action 2 ...
	* ...
	* description, location and functionality  of files added 
	* changes in files (what problem does it targets is the issue fixed)
	* to-do refrences if you have work to do in a file

example:
----------------------------------------------------------------------
-Author: Ahmed Medhioub
-Date  : 03-03-2014
-Title : Updating README.md with commit template and git instructions
-Description:
        * Adding clone, pull and push intructions to README.md 
	* Adding commit message template
----------------------------------------------------------------------

=====================================================================
= List of components
=====================================================================

this file contains a list and short description of all project 
directories used in ENSC 400 

* REG : 
	- Description: Basic read/write FF based register that is 
		used in all other projects
* SRAM : 
	- Description: Memory used in this project

* BUS : 
	- Description: Bus architecture
* UP_ISLAND :
	- Description: CPU block (CPU + BUS + 4 Slaves )
* Qrisc :
	- Description: CPU
* FIFO :
        - Description: fifo used in this project
* COUNTER : 
	- Description: counter used in this project
