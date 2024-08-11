# I modified this quick. Not sure why but whatevers. https://github.com/Will-Smith-007/TempClearer/tree/master
# --wl
import os
from shutil import rmtree
from pathlib import Path
from colorama import Fore, Style, init
from tabulate import tabulate

# Initialize colorama
init(autoreset=True)

prefix = f"{Fore.CYAN}[TempClearer]{Style.RESET_ALL}"

def get_directory_size(directory: str) -> int:
    """
    Returns the total size (in bytes) of all files in a given directory.
    """
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(directory):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            total_size += os.path.getsize(fp)
    return total_size

def clear_directory(directory: str) -> (int, int):
    """
    Deletes all files and folders in a given directory.
    Returns the size before and after cleaning.
    """
    if not os.path.exists(directory):
        print(f"{prefix} {Fore.RED}Directory {directory} does not exist.{Style.RESET_ALL}")
        return 0, 0

    initial_size = get_directory_size(directory)
    deleted_files = 0
    
    with os.scandir(directory) as entries:
        for entry in entries:
            entry_path = entry.path
            if not os.access(entry_path, os.W_OK):
                continue
            if os.path.isfile(entry_path):
                try:
                    os.remove(entry_path)
                    deleted_files += 1
                except PermissionError:
                    pass  # Ignore an error that can occur if the script doesn't have write permissions on the file.
            else:
                rmtree(entry_path, ignore_errors=True)
                deleted_files += 1

    final_size = get_directory_size(directory)
    removed_size = initial_size - final_size

    return initial_size, final_size

# Getting the Windows user path
current_user_dir = os.path.expanduser("~")
app_data_temp_dir = rf"{current_user_dir}\AppData\Local\Temp"
windows_temp_dir = r"C:\Windows\Temp"
pip_cache_dir = rf"{current_user_dir}\AppData\Local\pip\cache"

directories = [app_data_temp_dir, windows_temp_dir, pip_cache_dir]
total_removed_size = 0
table_data = []

print(f"{prefix} {Fore.YELLOW}Starting directory cleanup...{Style.RESET_ALL}")

for directory in directories:
    initial_size, final_size = clear_directory(directory)
    removed_size = initial_size - final_size
    total_removed_size += removed_size
    table_data.append([
        directory,
        f"{initial_size / (1024 * 1024):.2f} MB",
        f"{final_size / (1024 * 1024):.2f} MB",
        f"{removed_size / (1024 * 1024):.2f} MB"
    ])

# Print the table
print("\n" + tabulate(
    table_data,
    headers=[f"{Fore.CYAN}Directory{Style.RESET_ALL}", f"{Fore.YELLOW}Initial Size{Style.RESET_ALL}", f"{Fore.YELLOW}Final Size{Style.RESET_ALL}", f"{Fore.GREEN}Freed Space{Style.RESET_ALL}"],
    tablefmt="fancy_grid"
))

print(f"\n{prefix} {Fore.CYAN}Total freed space: {total_removed_size / (1024 * 1024):.2f} MB{Style.RESET_ALL}")
