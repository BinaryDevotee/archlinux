#
# install.sh
#

#!/bin/bash
set -e -u

echo "Simple Arch Linux installation script" && echo ""

echo 'a: profile-01.sh'
echo 'b: profile-02.sh'
echo 'c: profile-03.sh'
echo 'd: profile-04.sh'
echo 'q: exit'

echo ""

read -p 'Enter the desired installation profile: ' inst_profile

case $inst_profile in
  a) profiles/profile-01/profile-01.sh ;;
  b) profiles/profile-02/profile-02.sh ;;
  c) profiles/profile-03/profile-03.sh ;;
  d) profiles/profile-03/profile-04.sh ;;
  q) exit 0 ;;
  *) echo 'Invalid choice' ;;
esac
