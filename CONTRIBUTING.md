## How to contribute to the project

So you want to contribute to our project? Lovcely! The more hands we have on this, the faster we'll reach our goal to make the ultimate SS13 experience. Just follow these steps and you'll be ready to go! I'm going to assume you have a basic grasp of computers, like how to install programs and such. Command line experience optional but helpful.

Note that this will only cover how to use git to contribute, not to actually make whatever you're contributing with. In other words, if you need help in learning the programming language, how to map or how to draw icons for SS13, you're better off either, Googling it, hecking out one of the many resources I'll list at the bottom of this tutorial or asking me directly.

This tutorial assumes you'll be using Git Bash, but there are GUIs available. If you need help with those, I won't be able to help you, because I have little experience with them outside of them breaking all the time. In other words, I do not recommend you use one. Further, if you're having any issues understanding anything during the tutorial, feel free to look up external tutorials on Youtube, Github's own very well written documentation, or if you really want to dig deep, go check out Git's own manual. Very useful for checking out the potential of commands you've used daily, but never knew could do such things. Outside of that, Google will be your best friend.

### Setup

Assuming you've never used GitHub before, you'll need to create an account. Not exactly a complex ordeal, I won't say much other than recommend that you make a good, long password and use two-step authentication. Next, [fork the project](http://i.imgur.com/Ora85Dw.png?1). This will be your personal, perfect copy of the project, essentially your personal workspace.

Now, you need the tools of the trade. Or at least some of them. First of all, to create content at all, you'll need to install BYOND. Just download the latest you see from here: http://www.byond.com/download/ If there's a beta version available, ask Woothie if we're using that or not. Chances are no, but he might actually read the release notes and want to use some feature they've added. To be sure, just download the stable one, if you even have a choise.

Now you need a way to get the repository you just forked to your computer so you can work on it. [Download the latest git-scm](https://git-scm.com/downloads) and install it. During the installation process, things can mostly be kept at default [but here's a walkthrough just in case.](http://imgur.com/a/NUhJI)

This part is optional, but I personally recommend you install Notepad++ or another 3rd party text editor. I find the editor DreamMaker supplies a bit unintuitive and slow for coding and when searching through all the files for references and keywords. [You can find Notepad++ here.](https://notepad-plus-plus.org/download/v6.9.2.html)
To my knowledge it's only supported on Windows, so if you're a Mac or Linux user, don't bother. The DM editor isn't -that- bad. Mostly. The most important feature I find with this, aside from the cleaner interface, is that you can search for words in all files in a given folder, with or without filters, and you can even tell it to replace all those words with another word or phrase. Very handy.

Now you should have all the tools you need to get started. For convenience I also recommend you put Dream Maker and Git Bash as shortcuts on your desktop, task bar or start menu. Whatever suits you best. Next, open Git Bash and change directory (cd) to where you want the files to be. ([Example](http://i.imgur.com/1X2vrPu.png)) Then, copy the URL to your fork (that's https://github.com/yourusername/Eternal) and type in: 
```
git clone https://github.com/yourusername/Eternal
``` 
This part is going to take a few minutes, probably more, depending on your connection. Note that you don't have to make a folder spesifically for it beforehand, it'll make its own folder named Eternal inside the folder you're in. (In my case, this is C:/Users/Jonas, so it'll make C:/Users/Jonas/Eternal and populate it)

If everything went well, you should now have the repository downloaded and ready to edit. Make sure to move into this new folder by entering "cd Eternal". Before you start making delicious, wonderful content, you want to do some more setup things. First, run this command: 
```
git remote add upstream https://github.com/HeavensGate/Eternal
git remote -v
```
This will be used for when you want to keep up-to-date with the main repository. More on that later. The output should look [something like this.](http://i.imgur.com/sXuJePw.png)

When that's done, you're set. This part only has to be done when you delete the repository from your computer, usually to save space or because you ran into an issue that's taken too long to troubleshoot to be feasable to fix. These next steps will cover processes you'll have you familiarize yourself with, as you'll be doing it a lot.

### Keeping updated

Making sure you're up-to-date with the main rewhopository is something you'll have to do every time before, and in the case of lengthy sessions, during you making something. This assures that your content won't "collide" with anything someone else has done, among other things. If there are no conflicts, it's a pretty straight-forward procedure:
```
git fetch upstream/master
git merge upstream/master
git push
```
This is assuming you do this in Git Bash. You can also go to the webpage of your fork and make a pull request, if there's [anything new in the main repository](http://i.imgur.com/MeOff7p.png). All this isn't strightly neccesary if the only thing you're missing is a pull request you've made yourself, since it doesn't contain any changes itself. You can compare your fork and the main repository by clicking "Compare" right next to "Pull Request", and then clicking "switching the base". ([Example](http://i.imgur.com/MeOff7p.png)) Note how there are no commits, there's only a pull request that I've made. This means there has been no real change and you don't have to bother with it. 

If there are conflicts, you have to resolve the merge conflict before you can go any further. This can sometimes be a very time-consuming ordeal, and other times git will auto-merge it for you. If it's the latter, push the changes online and carry on working. If it's the first, GitHub has extensive documentation on different scenarios you might encounter. [Here's one from GitHub.](https://help.github.com/articles/resolving-a-merge-conflict-from-the-command-line/). The reason I'm just directing you do external resources for this is that merge conflicts can range wildly, and trying to put them all down here would make for a very lengthy tutorial, and a massive read. If that one doesn't help, try Googling your issue without spesific file names included. I'm certain a million other people have hit the same issue you have, but with differnt files and in a different environment. If all else fails, shout at Woothie for help. 

### Making it live

Now to the real stuff. First, it's helpful if you know at least vaugely how [our workflow works.](https://guides.github.com/introduction/flow/) Don't follow those steps blindly though, this is just an example of a good workflow, but it's near identical to how we work (he said smugly).
For anything above hotfixes and generally things you can do in under an hour, you want to create a new branch for whatever you're making. This assures that if you made changes later, it's all much more streamlined, and you'll also be able to work on other things while this one awaits validation by one of the project's admins, as well as a whole bunch of other good things. As an example, we'll start working on implementing Baystation12's new lighting system. We'll create a new branch and call it baylights:
```
git checkout -b baylights
```
You're now in sort of an alternate version of the folder, a mirror of the master phase, if you will. Changes you make won't be any different than if you were working on the master branch, but if you do (assuming you staged the changes you did here, more on that later):
```
git checkout master
```
in other words changing branches, you'll notice that those changes won't be there anymore. If you change back to baylights, they're back. I'm sure you get the idea. If you don't, don't worry. Go check out Github's documentation or Google around, you'll find something better written or more suited your way of thought, no doubt. 

Regardless, assuming you've done and tested whatever you're making, you will now stage all the files you've changed for commit, and then commit it. 
```
git add -A
git commit -m "Implemented bay lighting" -m "I foresee many a bug, else I will be very surprised indeed!"
```
The text inside the quotation marks will be the title and description of your commit, respectively. You can add more lines to the description by adding more -m arguments.  The title in particular is important, as it has to be descriptive. While we're here, I should remind you that if you're working on multiple things in one go, which is absoultely valid, you should try to make separate commits for each of them. This will make troubleshooting later much easier, and will look very nice and tidy on Github.

Next, when you're absolutely sure that everything works as it should, you'll probably want to put your changes online:
```
git push
``` 
This will ask for your username and password, and then take the commit(s) and send them to your repository on GitHub. When you're done pushing all the commits relevant to this branch, go to the website of your repository, change branches to the one you're working on and click "Pull request". Make sure the pull request is from the branch you're working on to the "Dev" branch of the main repository. The reason you're doing this, and not just putting it straight on the master branch, is to provice a buffer for troubleshooting and testing in live environments, in case something goes wrong. Name your pull request something descriptive and fill in the description if neccesary. If your changes fixes or generally address [a certain issue](https://github.com/HeavensGate/Eternal/issues), make sure to refer that either directly in the title (For example: "Fixes #5123 and #5122"). This way, if the pull request is accepted, those issues will automatically be closed. If they're simply menitioned in the title or description, your reviewers will have a handly link to whatever you're fixing or adding. 

### Conclusion & Resources

That should be it! If you find anything unclear or outright missing, give Woothie a shout and I'll get on it. If you're looking for things to do, go check out [the aforemenitioned issue tracker](https://github.com/HeavensGate/Eternal/issues) for things that need doing. Don't let the name fool you, we put more than just bugs and faults on this list. If the list is a bit overwhelming, filter by tags that are relevant for you (URGENT, bug, code, spriting, whatever it might be).

And as promised, a list of handy links:
- [GitHub Guides](https://guides.github.com/)
- [GitHub Documentation](https://help.github.com/)
- [Git Manual (godspeed)](https://git-scm.com/documentation)
- [BYOND Resource collab](http://www.byond.com/developer/articles/resources)
- [Helpful things from Baystation12's wiki](https://wiki.baystation12.net/Guide_to_Contributing_to_the_Game) 
  - NOTE: Some things on HG might deviate slightly or wildly from their codebase since we're well over a year out of sync, but it's very good material.
- [Skype group hotlink](https://join.skype.com/GHraMPCTWFOp)
- /tg/station developer IRC: irc://irc.rizon.net/coderbus
- Baystation12 developer IRC: irc://irc.sorcery.net/codershuttle

And remember: Test your shit before you commit, and backups save lives!


Baystation12 is licensed under the GNU Affero General Public License version 3, which can be found in full in LICENSE-AGPL3.txt or [here](http://www.gnu.org/licenses/agpl-3.0.html)

Heaven's Gate Station is licensed under the GNU Affero General Public License version 3 as well.

Commits with a git authorship date prior to `1420675200 +0000` (2015/01/08 00:00) are licensed under the GNU General Public License version 3, which can be found in full in LICENSE-GPL3.txt or [here](http://www.gnu.org/licenses/gpl-3.0.html).

All commits whose authorship dates are not prior to `1420675200 +0000` are assumed to be licensed under AGPL v3, if you wish to license under GPL v3 please make this clear in the commit message and any added files.
