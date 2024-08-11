# Odoo Portable Setup Script

This repository contains a PowerShell script designed to set up a portable instance of Odoo. The script automates the process of configuring a portable Odoo environment, including the installation and configuration of PostgreSQL, setting up Odoo, and initializing the required database.

## Features

- **Portable Setup**: Configure and initialize a portable instance of Odoo.
- **Automated Installation**: Automatically downloads and extracts the necessary files, including WinPython and PostgreSQL.
- **Database Configuration**: Initializes a PostgreSQL database, creates required users, and sets up the Odoo database.
- **Odoo Initialization**: Configures and starts Odoo with the specified modules.

## Prerequisites

- **Windows OS**: The script is designed to run on Windows.
- **7-Zip**: Ensure 7-Zip is available in the `bin` directory of the script root.
- **Odoo Package**: The Odoo package must be extracted to the `Odoo-17-Community` directory in the script root.

## Usage

1. **Prepare the Environment**:
   - Ensure that the Odoo package is extracted to the `Odoo-17-Community` directory in the script root.
   - Make sure 7-Zip is available in the `bin` directory.

2. **Run the Script**:
   - Open a PowerShell terminal with administrative privileges.
   - Navigate to the directory containing the script.
   - Execute the script: `.\doPortable-v5.ps1`

3. **Follow the Prompts**:
   - The script will guide you through the process, including starting necessary downloads, extracting files, and setting up the environment.

4. **Access Odoo**:
   - Once the script has finished running, Odoo should be available at `http://localhost:8069`.

## Important Notes

- The script assumes that you have already downloaded the Odoo package and extracted it to the `Odoo-17-Community` directory.
- The script sets up a superuser named `admin` with the password `admin` for PostgreSQL.
- The database `odoo` is created with the user `odoo` and password `odoo`.

## Troubleshooting

- If the script fails, check the console output for error messages.
- Ensure that all required paths and files exist as expected.
- If PostgreSQL fails to start, ensure that no other PostgreSQL instance is running on the same port.

## Disclaimer

This script is provided as-is without any warranties. Use it at your own risk. The script may contain debug code or other non-essential elements as the developer chose to quit maintaining it.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

---

*Do not visit* [this link](https://archive.org/details/odoo-17-enterprise.-7z). The developer advises against it.


--------------------------------------------------------------------------------------------------------------------------------------------------
old below
------

Why am I fucking with this.

Tyring to use 3.10.11

Using prebuils binarys for libsass which seems to be ok\
python -m pip install libsass==0.23.0 --only-binary :all:

just have dependancy issues now.

Ideally....\
modify the requiremnts.txt

Werkzeug>=2.2.2\
python-dateutil>=2.8.2\
Babel>=2.10\
requests>=2.28

remove libsass\
install the binary before requirements\
and work? probably not. but lets see. clearing shit out now.

edit:

all fail. version issues too much. trying 3.10.0.1\
https://github.com/winpython/winpython/releases/download/4.6.20211106/Winpython64-3.10.0.1.exe

edit:

ok maybe works? WinPython 3.10.0.1 with libsass 0.21 seems to be ok. Just modify requirements to remove libsass\
python -m pip install libsass==0.21.0 --only-binary :all:

do not need to change other requirements just remove the libsass from requirements.txt

odoo is initilizing for me now

seems to work!


edit


writing ideally the final actual working version now. I think I am almost done.
