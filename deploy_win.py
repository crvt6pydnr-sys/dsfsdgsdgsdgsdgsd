import os
import subprocess
import shutil

MINGW_BIN = "/usr/x86_64-w64-mingw32/sys-root/mingw/bin"
MINGW_PLUGINS = "/usr/x86_64-w64-mingw32/sys-root/mingw/lib/qt6/plugins"
MINGW_QML = "/usr/x86_64-w64-mingw32/sys-root/mingw/lib/qt6/qml"

def get_imports(filepath):
    try:
        out = subprocess.check_output(["x86_64-w64-mingw32-objdump", "-p", filepath], text=True)
        dlls = []
        for line in out.splitlines():
            if "DLL Name:" in line:
                dlls.append(line.split("DLL Name:")[1].strip())
        return dlls
    except Exception as e:
        print(f"Error reading imports for {filepath}: {e}")
        return []

def deploy():
    build_dir = "client/build_win"
    dist_dir = os.path.join(build_dir, "dist")
    
    # Clean up previous dist folder to prevent conflicts
    if os.path.exists(dist_dir):
        shutil.rmtree(dist_dir)
    os.makedirs(dist_dir, exist_ok=True)
    
    # 1. Copy main executable
    exe_path = os.path.join(build_dir, "tortu.exe")
    shutil.copy(exe_path, dist_dir)
    print(f"Copied main executable: {exe_path} -> {dist_dir}")
    
    # 2. Deploy platform plugin (required for GUI)
    plat_src = os.path.join(MINGW_PLUGINS, "platforms")
    if os.path.exists(plat_src):
        plat_dist = os.path.join(dist_dir, "platforms")
        os.makedirs(plat_dist, exist_ok=True)
        for f in os.listdir(plat_src):
            if f.endswith(".dll") and f == "qwindows.dll":
                shutil.copy(os.path.join(plat_src, f), plat_dist)
                print(f"Copied platform plugin: {f}")
                
    # 3. Deploy imageformats plugins (required for SVG/PNG/JPEG etc.)
    img_src = os.path.join(MINGW_PLUGINS, "imageformats")
    if os.path.exists(img_src):
        img_dist = os.path.join(dist_dir, "imageformats")
        os.makedirs(img_dist, exist_ok=True)
        for f in os.listdir(img_src):
            if f.endswith(".dll"):
                shutil.copy(os.path.join(img_src, f), img_dist)
                print(f"Copied imageformat plugin: {f}")

    # 4. Copy multimedia plugins (required for audio playback backend)
    multimedia_src = os.path.join(MINGW_PLUGINS, "multimedia")
    if os.path.exists(multimedia_src):
        multimedia_dist = os.path.join(dist_dir, "multimedia")
        os.makedirs(multimedia_dist, exist_ok=True)
        for f in os.listdir(multimedia_src):
            if f.endswith(".dll"):
                shutil.copy(os.path.join(multimedia_src, f), multimedia_dist)
                print(f"Copied multimedia plugin: {f}")

    # 4.5 Copy TLS plugins (required for SSL/HTTPS support)
    tls_src = os.path.join(MINGW_PLUGINS, "tls")
    if os.path.exists(tls_src):
        tls_dist = os.path.join(dist_dir, "tls")
        os.makedirs(tls_dist, exist_ok=True)
        for f in os.listdir(tls_src):
            if f.endswith(".dll"):
                shutil.copy(os.path.join(tls_src, f), tls_dist)
                print(f"Copied TLS plugin: {f}")

    # 5. Deploy QML directory modules
    qml_dist = os.path.join(dist_dir, "qml")
    os.makedirs(qml_dist, exist_ok=True)
    
    qml_modules = ["QtCore", "QtQml", "QtQuick", "QtMultimedia", "Qt"]
    for module in qml_modules:
        src_mod = os.path.join(MINGW_QML, module)
        if os.path.exists(src_mod):
            shutil.copytree(src_mod, os.path.join(qml_dist, module), dirs_exist_ok=True)
            print(f"Copied QML module: {module}")

    # 5.5 Copy OpenSSL DLLs (required for HTTPS support at runtime)
    for ossl in ["libssl-3-x64.dll", "libcrypto-3-x64.dll", "libssl-1_1-x64.dll", "libcrypto-1_1-x64.dll"]:
        src_ossl = os.path.join(MINGW_BIN, ossl)
        if os.path.exists(src_ossl):
            shutil.copy(src_ossl, dist_dir)
            print(f"Pre-copied OpenSSL library: {ossl}")

    # 6. Unified recursive scan of all executable/plugin DLLs in the output directory
    copied = set()
    queue = []
    
    # Scan dist folder for files to seed the BFS queue
    for root, dirs, files in os.walk(dist_dir):
        for f in files:
            if f.endswith(".dll") or f.endswith(".exe"):
                full_path = os.path.join(root, f)
                copied.add(f.lower())
                queue.append(full_path)
                
    print(f"Unified queue seeded with {len(queue)} binaries. Scanning recursively...")
    
    while queue:
        current_path = queue.pop(0)
        imports = get_imports(current_path)
        for dll in imports:
            dll_lower = dll.lower()
            if dll_lower in copied:
                continue
                
            src_path = os.path.join(MINGW_BIN, dll)
            if not os.path.exists(src_path):
                # Case insensitive fallback search
                for f in os.listdir(MINGW_BIN):
                    if f.lower() == dll_lower:
                        src_path = os.path.join(MINGW_BIN, f)
                        break
            
            if os.path.exists(src_path):
                dest_path = os.path.join(dist_dir, os.path.basename(src_path))
                shutil.copy(src_path, dest_path)
                copied.add(dll_lower)
                queue.append(dest_path)
                print(f"Copied DLL dependency: {dll_lower} (for {os.path.basename(current_path)})")

    # 7. Write qt.conf to dist directory
    qt_conf_path = os.path.join(dist_dir, "qt.conf")
    with open(qt_conf_path, "w") as f:
        f.write("[Paths]\nPrefix = .\nPlugins = .\nImports = qml\nQml2Imports = qml\n")
    print("Created qt.conf")

if __name__ == "__main__":
    deploy()
