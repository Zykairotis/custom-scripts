# cvt-txt.sh

A high-performance Bash script that safely converts text-based files to UTF-8 plain text format with intelligent MIME type detection and parallel processing.

## ✨ Features

- **Smart file detection** - Only processes text-compatible files (skips binaries like MP4, PNG, etc.)
- **Multi-format support** - Handles PDF, DOCX, ODT, HTML via `pdftotext` and `pandoc`
- **Parallel processing** - Utilizes all CPU cores for maximum speed
- **Flexible filtering** - Include/exclude patterns with glob support
- **Encoding normalization** - Fixes UTF-8 issues and line endings
- **Dry-run mode** - Preview operations before execution
- **Progress logging** - Detailed conversion reports

## 🚀 Installation

```bash
# Install to system PATH
sudo cp cvt-txt.sh /usr/local/bin/cvt-txt
sudo chmod +x /usr/local/bin/cvt-txt

# Install optional dependencies for enhanced conversion
sudo pacman -S poppler pandoc dos2unix  # Arch Linux
```

## 📖 Usage Examples

### Basic Operations
```bash
# Convert current directory
cvt-txt

# Convert specific folder to output directory
cvt-txt --input ~/Documents --output ~/text-backup
```

### Development Projects
```bash
# Python project (code + docs only)
cvt-txt --input ~/my-project \
  --include '*.py' --include '*.md' --include '*.yml' \
  --exclude '__pycache__/*' --exclude '.git/*'

# React/Node.js project
cvt-txt --include '*.js' --include '*.jsx' --include '*.ts' --include '*.tsx' \
  --exclude 'node_modules/*' --exclude 'build/*'
```

### Documentation Processing
```bash
# Convert mixed document formats
cvt-txt --input ~/writing \
  --include '*.md' --include '*.docx' --include '*.pdf' --include '*.html'

# Extract all configuration files
cvt-txt --include '*.conf' --include '*.json' --include '*.yml' --include '*.toml'
```

### Safety and Testing
```bash
# Preview what would be converted
cvt-txt --dry-run --input ~/large-project --include '*.py'

# Complex enterprise filtering
cvt-txt --input ~/enterprise-app \
  --include '*.java' --include '*.xml' --include '*.properties' \
  --exclude 'target/*' --exclude '*.jar' --exclude 'logs/*'
```

## 🛠️ Requirements

- **Bash 4.0+**
- **GNU findutils, coreutils**
- **file** command (MIME detection)

### Optional (for enhanced conversion):
- `poppler` - PDF to text conversion
- `pandoc` - Office documents (DOCX, ODT, HTML)
- `dos2unix` - Line ending normalization
- `iconv` - Character encoding fixes

## 📝 Options

| Option | Description | Example |
|--------|-------------|---------|
| `--input DIR` | Source directory | `--input ~/projects` |
| `--output DIR` | Destination directory | `--output ~/converted` |
| `--include PATTERN` | Include files matching glob | `--include '*.py'` |
| `--exclude PATTERN` | Exclude files matching glob | `--exclude 'node_modules/*'` |
| `--dry-run` | Preview without converting | `--dry-run` |
| `--help` | Show usage information | `--help` |

## 🎯 Common Use Cases

- **Code analysis preparation** - Extract all source code to searchable text
- **Document backup** - Convert mixed formats to uniform plain text
- **AI training data** - Prepare clean text datasets from file trees
- **Migration assistance** - Extract content before system changes
- **Search index creation** - Make file contents full-text searchable

# cvt-comb - File Combiner

`cvt-comb` is a shell script that scans a directory and combines files into folder-wise summary files. It is useful for creating a single text file from a directory of text files, for example, to be used as context for a large language model.

## Features

- Combines files from subdirectories into individual summary files.
- Combines files from the root directory into a `root.txt` summary file.
- Customizable file pattern to combine different types of files.
- Customizable output directory.
- Silent mode to suppress informational output.
- Help message with usage instructions and examples.

## Usage

```bash
./cvt-comb [OPTIONS] [INPUT_DIRECTORY]
```

### Arguments

- `INPUT_DIRECTORY`: The directory to process. Defaults to the current directory.

### Options

- `-o, --output DIR`: Set the output directory. Defaults to `combined_output`.
- `-p, --pattern PATT`: Set the file search pattern. Defaults to `*.txt`.
- `-h, --help`: Display the help message and exit.
- `-s, --silent`: Suppress all informational output.

### Examples

- **Process the current directory:**

  ```bash
  ./cvt-comb
  ```

- **Process a specific directory:**

  ```bash
  ./cvt-comb /path/to/your/files
  ```

- **Set a custom output directory:**

  ```bash
  ./cvt-comb -o ./my-combined-files
  ```

- **Combine all `.js` files:**

  ```bash
  ./cvt-comb -p "*.js"
  ```

## How it Works

The script performs the following actions:

1.  Parses command-line arguments to set the input directory, output directory, file pattern, and silent mode.
2.  Validates that the input directory exists and is not the same as the output directory.
3.  Creates the output directory if it doesn't exist.
4.  For each subdirectory in the input directory, it creates a summary file (e.g., `auth.txt`).
5.  It then finds all files matching the file pattern within that subdirectory and appends their contents to the summary file.
6.  For all files in the root of the input directory, it creates a `root.txt` summary file and appends their contents.
7.  Each combined file includes a header indicating the original file path.


## 📄 License

MIT License - Feel free to modify and distribute.
