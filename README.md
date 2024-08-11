Why am I fucking with this.

Tyring to use 3.10.11 

Using prebuils binarys for libsass which seems to be ok
python -m pip install libsass==0.23.0 --only-binary :all:

just have dependancy issues now. 

Ideally....
modify the requiremnts.txt 

Werkzeug>=2.2.2
python-dateutil>=2.8.2
Babel>=2.10
requests>=2.28

remove libsass
install the binary before requirements
and work? probably not. but lets see. clearing shit out now. 



edit:

all fail. version issues too much. trying 3.10.0.1
https://github.com/winpython/winpython/releases/download/4.6.20211106/Winpython64-3.10.0.1.exe


edit:

ok maybe works? WinPython 3.10.0.1 with libsass 0.21 seems to be ok. Just modify requirements to remove libsass
python -m pip install libsass==0.21.0 --only-binary :all:

odoo is initilizing for me now
