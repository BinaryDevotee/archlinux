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
echo 'e: profile-05.sh'
echo 'q: exit'

echo ""

read -p 'Enter the desired installation profile: ' inst_profile

case $inst_profile in
  a) cat profiles/profile-01.sh ;;
  b) cat profiles/profile-02.sh ;;
  c) cat profiles/profile-03.sh ;;
  d) cat profiles/profile-04.sh ;;
  e) cat profiles/profile-06.sh ;;
  q) exit 0 ;;
  *) echo 'Invalid choice' ;;
esac
