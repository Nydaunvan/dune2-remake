// Installateur / désinstalleur de « The Building of a Dynasty » (Windows, sans droits administrateur).
//
//	Setup.exe            assistant d'installation (dossier, raccourci bureau, lancement)
//	Setup.exe /S         installation silencieuse (/D=dossier, /nodesktop)
//	Setup.exe /update    mise à jour lancée par le jeu : attend sa fermeture, remplace les fichiers, relance le jeu
//	uninstall.exe        désinstalleur (même programme, copié dans le dossier d'installation)
//
// La charge utile (payload.zip : jeu, icône, désinstalleur) est intégrée à l'exécutable.
package main

import (
	"archive/zip"
	"bytes"
	_ "embed"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

//go:embed payload.zip
var payloadZip []byte

var version = "dev"

const (
	appName   = "The Building of a Dynasty"
	exeName   = "TheBuildingOfADynasty.exe"
	uninstExe = "uninstall.exe"
	iconName  = "icon.ico"
	regKey    = `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\TheBuildingOfADynasty`
	publisher = "Nydaunvan"
)

// ---------------------------------------------------------------------------------------------

var msgBoxProc = syscall.NewLazyDLL("user32.dll").NewProc("MessageBoxW")

const (
	mbOK         = 0x0
	mbYesNo      = 0x4
	mbIconError  = 0x10
	mbIconAsk    = 0x20
	mbIconInfo   = 0x40
	mbForeground = 0x10000
	idYes        = 6
)

func box(text string, flags uintptr) int {
	t, _ := syscall.UTF16PtrFromString(text)
	c, _ := syscall.UTF16PtrFromString(appName)
	r, _, _ := msgBoxProc.Call(0, uintptr(unsafe.Pointer(t)), uintptr(unsafe.Pointer(c)), flags|mbForeground)
	return int(r)
}

func yes(text string) bool { return box(text, mbYesNo|mbIconAsk) == idYes }
func info(text string)     { box(text, mbOK|mbIconInfo) }
func fail(text string)     { box(text, mbOK|mbIconError) }

// hidden : commande sans fenêtre console.
func hidden(name string, args ...string) *exec.Cmd {
	c := exec.Command(name, args...)
	c.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	return c
}

func q(s string) string { return "'" + strings.ReplaceAll(s, "'", "''") + "'" }

func ps(script string) (string, error) {
	out, err := hidden("powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", script).Output()
	return strings.TrimSpace(string(out)), err
}

func retry(total time.Duration, f func() error) error {
	end := time.Now().Add(total)
	for {
		err := f()
		if err == nil || time.Now().After(end) {
			return err
		}
		time.Sleep(500 * time.Millisecond)
	}
}

// ---------------------------------------------------------------------------------------------

type options struct {
	silent    bool
	update    bool
	uninstall bool
	run       bool // deuxième étape du désinstalleur (copie temporaire)
	dir       string
	noDesktop bool
	desktop   bool
}

func parseArgs() options {
	var o options
	for _, a := range os.Args[1:] {
		low := strings.ToLower(a)
		switch {
		case low == "/s" || low == "/silent" || low == "/verysilent":
			o.silent = true
		case low == "/update":
			o.update = true
			o.silent = true
		case low == "/uninstall":
			o.uninstall = true
		case low == "/run":
			o.run = true
		case low == "/nodesktop":
			o.noDesktop = true
		case low == "/desktop":
			o.desktop = true
		case strings.HasPrefix(low, "/d="):
			o.dir = strings.Trim(a[3:], `"`)
		default:
			if o.run && o.dir == "" {
				o.dir = strings.Trim(a, `"`)
			}
		}
	}
	return o
}

func defaultDir() string {
	base := os.Getenv("LOCALAPPDATA")
	if base == "" {
		base = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Local")
	}
	return filepath.Join(base, "Programs", appName)
}

// existingDir : dossier d'une installation précédente (registre), sinon "".
func existingDir() string {
	out, err := hidden("reg", "query", regKey, "/v", "InstallLocation").Output()
	if err != nil {
		return ""
	}
	for _, ln := range strings.Split(string(out), "\n") {
		if i := strings.Index(ln, "REG_SZ"); i >= 0 {
			d := strings.TrimSpace(ln[i+len("REG_SZ"):])
			if _, e := os.Stat(filepath.Join(d, exeName)); e == nil {
				return d
			}
		}
	}
	return ""
}

func pickDir(start string) string {
	script := "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.FolderBrowserDialog; " +
		"$f.Description='Choisissez le dossier parent : un sous-dossier ' + " + q(appName) + " + ' y sera créé.'; " +
		"$f.SelectedPath=" + q(filepath.Dir(start)) + "; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"
	out, err := ps(script)
	if err != nil || out == "" {
		return ""
	}
	return filepath.Join(out, appName)
}

// ---------------------------------------------------------------------------------------------
// Installation

func writeFile(dest string, r io.Reader, wait time.Duration) error {
	tmp := dest + ".new"
	f, err := os.Create(tmp)
	if err != nil {
		return err
	}
	if _, err = io.Copy(f, r); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	f.Close()
	return retry(wait, func() error {
		os.Remove(dest)
		return os.Rename(tmp, dest)
	})
}

func extractPayload(dir string, wait time.Duration) (int64, error) {
	zr, err := zip.NewReader(bytes.NewReader(payloadZip), int64(len(payloadZip)))
	if err != nil {
		return 0, err
	}
	var size int64
	for _, f := range zr.File {
		if f.FileInfo().IsDir() {
			continue
		}
		rc, err := f.Open()
		if err != nil {
			return 0, err
		}
		err = writeFile(filepath.Join(dir, filepath.Base(f.Name)), rc, wait)
		rc.Close()
		if err != nil {
			return 0, fmt.Errorf("%s : %w", f.Name, err)
		}
		size += int64(f.UncompressedSize64)
	}
	return size, nil
}

func makeShortcut(where, folder, name, target, args, dir, icon, desc string) {
	script := "$d=[Environment]::GetFolderPath(" + q(where) + "); "
	if folder != "" {
		script += "$d=Join-Path $d " + q(folder) + "; "
	}
	script += "New-Item -ItemType Directory -Force $d | Out-Null; " +
		"$s=(New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $d " + q(name+".lnk") + ")); " +
		"$s.TargetPath=" + q(target) + "; $s.Arguments=" + q(args) + "; $s.WorkingDirectory=" + q(dir) + "; " +
		"$s.IconLocation=" + q(icon) + "; $s.Description=" + q(desc) + "; $s.Save()"
	ps(script)
}

func desktopShortcutExists() bool {
	out, err := ps("Test-Path (Join-Path ([Environment]::GetFolderPath('Desktop')) " + q(appName+".lnk") + ")")
	return err == nil && strings.EqualFold(out, "True")
}

func registerUninstall(dir string, sizeBytes int64) {
	un := filepath.Join(dir, uninstExe)
	set := func(name, typ, val string) {
		hidden("reg", "add", regKey, "/v", name, "/t", typ, "/d", val, "/f").Run()
	}
	set("DisplayName", "REG_SZ", appName)
	set("DisplayVersion", "REG_SZ", version)
	set("Publisher", "REG_SZ", publisher)
	set("InstallLocation", "REG_SZ", dir)
	set("DisplayIcon", "REG_SZ", filepath.Join(dir, iconName))
	set("UninstallString", "REG_SZ", `"`+un+`" /uninstall`)
	set("QuietUninstallString", "REG_SZ", `"`+un+`" /uninstall /S`)
	set("InstallDate", "REG_SZ", time.Now().Format("20060102"))
	set("EstimatedSize", "REG_DWORD", fmt.Sprint(sizeBytes/1024))
	set("NoModify", "REG_DWORD", "1")
	set("NoRepair", "REG_DWORD", "1")
}

func install(o options) {
	dir := o.dir
	prev := existingDir()
	if dir == "" {
		dir = prev
	}
	if dir == "" {
		dir = defaultDir()
	}
	hadDesktop := prev != "" && desktopShortcutExists()
	desktop := !o.noDesktop

	if !o.silent {
		msg := fmt.Sprintf("Bienvenue dans l'installation de %s (version %s).\n\nDossier d'installation :\n%s\n\nContinuer ?", appName, version, dir)
		if prev != "" {
			msg = fmt.Sprintf("%s (version %s) est déjà installé dans :\n%s\n\nMettre à jour cette installation ? Vos sauvegardes sont conservées.", appName, version, prev)
		}
		if !yes(msg) {
			return
		}
		if prev == "" && !yes("Installer dans ce dossier ?\n\nChoisissez « Non » pour sélectionner un autre emplacement.") {
			d := pickDir(dir)
			if d == "" {
				return
			}
			dir = d
		}
		if prev != "" {
			desktop = hadDesktop || yes("Ajouter aussi un raccourci sur le bureau ?")
		} else {
			desktop = yes("Créer un raccourci sur le bureau ?")
		}
	} else if o.update {
		desktop = hadDesktop
	} else if o.desktop {
		desktop = true
	}

	if err := os.MkdirAll(dir, 0o755); err != nil {
		if !o.silent {
			fail("Impossible de créer le dossier :\n" + dir + "\n\n" + err.Error())
		}
		os.Exit(1)
	}
	wait := 20 * time.Second
	if o.update {
		wait = 120 * time.Second // le jeu se ferme juste après avoir lancé la mise à jour
	}
	size, err := extractPayload(dir, wait)
	if err != nil {
		if !o.silent {
			fail("L'installation a échoué :\n" + err.Error() + "\n\nSi le jeu est ouvert, fermez-le puis réessayez.")
		}
		os.Exit(1)
	}

	exe := filepath.Join(dir, exeName)
	ico := filepath.Join(dir, iconName)
	makeShortcut("Programs", appName, appName, exe, "", dir, ico, appName)
	makeShortcut("Programs", appName, "Désinstaller "+appName, filepath.Join(dir, uninstExe), "/uninstall", dir, ico, "Désinstaller "+appName)
	if desktop {
		makeShortcut("Desktop", "", appName, exe, "", dir, ico, appName)
	}
	registerUninstall(dir, size)

	launch := func() {
		c := exec.Command(exe)
		c.Dir = dir
		c.Start()
	}
	if o.update {
		launch()
		return
	}
	if o.silent {
		return
	}
	if yes("L'installation est terminée.\n\nLancer " + appName + " maintenant ?") {
		launch()
	}
}

// ---------------------------------------------------------------------------------------------
// Désinstallation

func userDataDir() string {
	return filepath.Join(os.Getenv("APPDATA"), "Godot", "app_userdata", appName)
}

func uninstallFirstStage(o options) {
	self, err := os.Executable()
	if err != nil {
		return
	}
	dir := filepath.Dir(self)
	if _, e := os.Stat(filepath.Join(dir, exeName)); e != nil {
		fail("Ce programme doit être lancé depuis le dossier d'installation du jeu.")
		return
	}
	if !o.silent && !yes("Désinstaller "+appName+" ?\n\nLe dossier suivant sera supprimé :\n"+dir) {
		return
	}
	// Une copie temporaire termine le travail (le programme en cours ne peut pas se supprimer lui-même)
	tmp := filepath.Join(os.TempDir(), fmt.Sprintf("dd_uninstall_%d.exe", os.Getpid()))
	data, err := os.ReadFile(self)
	if err == nil {
		err = os.WriteFile(tmp, data, 0o755)
	}
	if err != nil {
		fail("Impossible de préparer la désinstallation :\n" + err.Error())
		return
	}
	args := []string{"/uninstall", "/run", dir}
	if o.silent {
		args = append(args, "/S")
	}
	c := exec.Command(tmp, args...)
	c.Start()
}

func uninstallSecondStage(o options) {
	dir := o.dir
	if _, err := os.Stat(filepath.Join(dir, exeName)); err != nil {
		return
	}
	time.Sleep(time.Second)
	wipeSaves := false
	if !o.silent {
		if _, err := os.Stat(userDataDir()); err == nil {
			wipeSaves = yes("Supprimer aussi vos sauvegardes et réglages ?\n\nChoisissez « Non » pour les conserver (utile si vous réinstallez le jeu).")
		}
	}
	ps("Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path ([Environment]::GetFolderPath('Programs')) " + q(appName) + "); " +
		"Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path ([Environment]::GetFolderPath('Desktop')) " + q(appName+".lnk") + ")")
	hidden("reg", "delete", regKey, "/f").Run()
	err := retry(30*time.Second, func() error { return os.RemoveAll(dir) })
	if wipeSaves {
		os.RemoveAll(userDataDir())
	}
	// supprime la copie temporaire une fois ce processus terminé
	self, _ := os.Executable()
	c := hidden("cmd")
	c.SysProcAttr.CmdLine = `cmd /c ping -n 3 127.0.0.1 >nul & del /f /q "` + self + `"`
	c.Start()
	if !o.silent {
		if err != nil {
			fail("Certains fichiers n'ont pas pu être supprimés (jeu encore ouvert ?) :\n" + dir)
		} else {
			info(appName + " a été désinstallé.")
		}
	}
}

// ---------------------------------------------------------------------------------------------

func main() {
	o := parseArgs()
	if len(payloadZip) < 100 && !o.uninstall {
		fail("Programme d'installation incomplet (charge utile absente).")
		return
	}
	switch {
	case o.uninstall && o.run:
		uninstallSecondStage(o)
	case o.uninstall:
		uninstallFirstStage(o)
	default:
		install(o)
	}
}

var _ = errors.New
