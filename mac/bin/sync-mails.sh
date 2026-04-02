# Sync local mail setup with remotes

source $HOME/.zsecrets
# to delete old mails in trash: find ~/.Maildir/uberspace/Trash/cur -type f -mtime +90 -delete # >> /Users/johannes/mail.log 2>&1
mbsync -a # >> /Users/johannes/mail.log 2>&1
notmuch new
