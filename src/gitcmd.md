# not connect to github website, just work locally.
# the source code directory will be  project -> src .
there are 3 bash files in this directory now.
the object is to put them under git management.
to push to github website, must use ssh. origin must setup to ssh address. instead of https.
# steps bellow
## cd project/src
## git config --global user.name liyuefu
## git config --global user.email yuuefuli@gmail.com
## git config --global init.default branch main
## git init 
this cmd will create .git directory under src .
## git status
should show no files.
## git add .
add 3 files to staging. 
next need to be committed.
## git status
shows 3 files in staging.
## git commit -m 'initial version'
commit 3 files.
## git status
show no files need to be commited.
## vi readme.md
create a readme.md files
## git status
shows readme.md is untracked.
## git add readme.md
or just git add .
## git status
shows readme.md can be committed.
## git commit -m 'added readme.md'

## vi readme.txt 
add one line "new line"
## git status
shows readme.md is changed.
## git diff
show the difference between old and new version.

## git restore 
restore the old version(with new line)

## git log
check all the commits.
git log --oneline
show simple one line comments
git log -p
git help log(get more help of log)
## git branch bugfix
git branch to check all the branches
git switch bugfix , switch to another bransh.
## git merge -m 'merge comment' bugfix
git merge -m 'merge with bugfix in t2.sh' bugfix
merge bugfix branch to master 
## git branch -d bugfix
after bugfix is merged, delete the bugfix branch.
git branch to check it.

## git switch -c newbranch
create a new branch "newbranch" and switch to it.

## add local to github 
-- this is for https, git remote add origin https://github.com/liyuefu/autodg.git
git remote add git@github.com:liyuefu/Git-Commands.git
git branch -M main
git push -u origin main
git push --all (all branches)

## git pull
download from github to local.



#######################error######################

[nome@LIYUEFU-T14 src-test]$ git push -u origin main
Username for 'https://github.com': yuefuli@gmail.com
Password for 'https://yuefuli@gmail.com@github.com':
remote: Support for password authentication was removed on August 13, 2021.
remote: Please see https://docs.github.com/get-started/getting-started-with-git/about-remote-repositories#cloning-with-https-urls for information on currently recommended modes of authentication.
fatal: Authentication failed for 'https://github.com/liyuefu/autodg.git/'

fix: https://youtu.be/RGOj5yH7evk
1. ssh-keygen -t rsa -b 4096 -C "yuefuli@gmail.com"
create ssh key. just return when prompted.
2. cd ~/.ssh/ 
cat id_rsa.pub , copy to paste.
3. open github ->setting -> ssh key. paste it.
4. local  evel "$(ssh-agent -s)" 
5. local ssh-add ~/ssh/id_rsa
6. local, test it. ssh git@github.com
returns: 
PTY allocation request failed on channel 0
Hi liyuefu! You've successfully authenticated, but GitHub does not provide shell access.
Connection to github.com closed.
it says ok

###################################example###############
[nome@LIYUEFU-T14 src-test]$ eval "$(ssh-agent -s)"
Agent pid 937
[nome@LIYUEFU-T14 src-test]$ ssh-add ~/.ssh/
id_ed25519       id_ed25519.pub   id_rsa           id_rsa.pub       known_hosts      known_hosts.old
[nome@LIYUEFU-T14 src-test]$ ssh-add ~/.ssh/id_rsa
Identity added: /home/nome/.ssh/id_rsa (yuefuli@gmail.com)
[nome@LIYUEFU-T14 src-test]$ ssh git@github.com
PTY allocation request failed on channel 0
Hi liyuefu! You've successfully authenticated, but GitHub does not provide shell access.
Connection to github.com closed.
[nome@LIYUEFU-T14 src-test]$



#############after ssh @git@github.com, still error:
[nome@LIYUEFU-T14 src-test]$ git push -u origin main
Username for 'https://github.com': yuefuli@gmail.com
Password for 'https://yuefuli@gmail.com@github.com':
remote: Invalid username or password.
fatal: Authentication failed for 'https://github.com/liyuefu/autodg.git/'
[nome@LIYUEFU-T14 src-test]$
