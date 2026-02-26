source $HOME/.zsecrets
# echo "==== $(date +%T) Start =====" >> /Users/johannes/mail.log
# to delete old mails in trash: find ~/Maildir/uberspace/Trash/cur -type f -mtime +90 -delete # >> /Users/johannes/mail.log 2>&1 
mbsync -a # >> /Users/johannes/mail.log 2>&1
notmuch new
# echo "==== $(date +%T) Done =====" >> /Users/johannes/mail.log

