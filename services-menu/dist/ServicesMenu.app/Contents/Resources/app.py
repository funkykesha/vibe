#!/usr/bin/env python3
import glob
import os
import plistlib
import re
import rumps
import subprocess
from AppKit import (
    NSAlert,
    NSApplication,
    NSApp,
    NSBackingStoreBuffered,
    NSButton,
    NSMenu,
    NSMenuItem,
    NSTextField,
    NSWindow,
    NSWindowStyleMaskClosable,
    NSWindowStyleMaskTitled,
)
from Foundation import NSMakeRect

LABEL_PREFIX = "com.agaibadulin"
SERVICES_MENU_LABEL = f"{LABEL_PREFIX}.services-menu"
SERVICES_MENU_APP_PATH = "/Applications/ServicesMenu.app"
LAUNCH_AGENTS_DIR = os.path.expanduser("~/Library/LaunchAgents")
LOG_ROOT_DIR = os.path.expanduser("~/Library/Logs")
SAFE_NAME_RE = re.compile(r"^[A-Za-z0-9_-]+$")
WHICH_PATH = "/usr/bin/which"
WHICH_ENV_PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"


class ValidationError(Exception):
    pass


def validate_service_name(value):
    name = (value or "").strip()
    if not name:
        raise ValidationError("Name is required.")
    if not SAFE_NAME_RE.fullmatch(name):
        raise ValidationError("Name supports letters, digits, '-' and '_' only.")
    return name


def build_launch_agent_config(name, command, path_to_start, working_directory):
    command_value = (command or "").strip()
    path_value = (path_to_start or "").strip()
    if not command_value:
        raise ValidationError("Command is required.")
    if not path_value:
        raise ValidationError("Path to start is required.")

    label = f"{LABEL_PREFIX}.{name}"
    log_dir = os.path.join(LOG_ROOT_DIR, name)
    payload = {
        "Label": label,
        "ProgramArguments": [command_value, path_value],
        "RunAtLoad": True,
        "KeepAlive": True,
        "StandardOutPath": os.path.join(log_dir, "stdout.log"),
        "StandardErrorPath": os.path.join(log_dir, "error.log"),
    }
    working_dir_value = (working_directory or "").strip()
    if working_dir_value:
        payload["WorkingDirectory"] = working_dir_value
    return payload


def resolve_command_with_which(command, runner=subprocess.run):
    command_value = (command or "").strip()
    if not command_value:
        raise ValidationError("Command is required.")

    env = os.environ.copy()
    env["PATH"] = WHICH_ENV_PATH
    result = runner(
        [WHICH_PATH, command_value],
        capture_output=True,
        text=True,
        env=env,
    )
    resolved = (result.stdout or "").strip()
    if result.returncode != 0 or not resolved:
        details = (result.stderr or "").strip()
        if details:
            raise ValidationError(f"Command not found: {details}")
        raise ValidationError(f"Command not found: {command_value}")
    return resolved


def create_launch_agent_plist(name, command, path_to_start, working_directory):
    service_name = validate_service_name(name)
    payload = build_launch_agent_config(service_name, command, path_to_start, working_directory)
    plist_path = os.path.join(LAUNCH_AGENTS_DIR, f"{LABEL_PREFIX}.{service_name}.plist")
    log_dir = os.path.join(LOG_ROOT_DIR, service_name)

    if os.path.exists(plist_path):
        raise ValidationError(f"Config already exists: {plist_path}")

    os.makedirs(LAUNCH_AGENTS_DIR, exist_ok=True)
    os.makedirs(log_dir, exist_ok=True)

    with open(plist_path, "wb") as fh:
        plistlib.dump(payload, fh)

    return plist_path


def build_services_menu_launch_agent_config():
    return {
        "Label": SERVICES_MENU_LABEL,
        "ProgramArguments": ["open", SERVICES_MENU_APP_PATH],
        "RunAtLoad": True,
        "KeepAlive": False,
        "StandardOutPath": os.path.join(LOG_ROOT_DIR, "services-menu.log"),
        "StandardErrorPath": os.path.join(LOG_ROOT_DIR, "services-menu-error.log"),
    }


def discover_service_labels():
    pattern = os.path.join(LAUNCH_AGENTS_DIR, f"{LABEL_PREFIX}.*.plist")
    labels = set()
    for plist_path in glob.glob(pattern):
        try:
            with open(plist_path, "rb") as fh:
                payload = plistlib.load(fh)
        except Exception:
            continue

        label = payload.get("Label")
        if not isinstance(label, str):
            continue
        if not label.startswith(f"{LABEL_PREFIX}."):
            continue
        if label == SERVICES_MENU_LABEL:
            continue
        labels.add(label)

    return sorted(labels, key=str.lower)

def get_status(label):
    try:
        result = subprocess.run(
            ["launchctl", "list"],
            capture_output=True, text=True
        )
        for line in result.stdout.splitlines():
            if label in line:
                parts = line.split()
                pid = parts[0]
                return "🟢" if pid != "-" else "🔴"
        return "⚪"
    except Exception:
        return "❓"

def restart_service(label):
    subprocess.run(["launchctl", "stop", label])
    subprocess.run(["launchctl", "start", label])


class AddConfigWindowController:
    def __init__(self, on_apply):
        self.on_apply = on_apply
        self.window = NSWindow.alloc().initWithContentRect_styleMask_backing_defer_(
            NSMakeRect(0, 0, 560, 220),
            NSWindowStyleMaskTitled | NSWindowStyleMaskClosable,
            NSBackingStoreBuffered,
            False,
        )
        self.window.setTitle_("Add LaunchAgent Config")
        self.window.center()
        self.window.setReleasedWhenClosed_(False)

        content = self.window.contentView()
        self.name_field = self._add_field(content, "Name", 166)
        self.command_field = self._add_field(content, "Command", 126)
        self.which_button = NSButton.alloc().initWithFrame_(NSMakeRect(456, 126, 92, 28))
        self.which_button.setTitle_("Which")
        self.which_button.setTarget_(self)
        self.which_button.setAction_("whichClicked:")
        content.addSubview_(self.which_button)
        self.command_field.setFrame_(NSMakeRect(176, 126, 272, 28))
        self.path_field = self._add_field(content, "Path to start", 86)
        self.workdir_field = self._add_field(content, "WorkingDirectory", 46)

        self.cancel_button = NSButton.alloc().initWithFrame_(NSMakeRect(360, 8, 90, 28))
        self.cancel_button.setTitle_("Cancel")
        self.cancel_button.setTarget_(self)
        self.cancel_button.setAction_("cancelClicked:")
        content.addSubview_(self.cancel_button)

        self.apply_button = NSButton.alloc().initWithFrame_(NSMakeRect(458, 8, 90, 28))
        self.apply_button.setTitle_("Apply")
        self.apply_button.setTarget_(self)
        self.apply_button.setAction_("applyClicked:")
        content.addSubview_(self.apply_button)

    def _add_field(self, content, label, y):
        title = NSTextField.alloc().initWithFrame_(NSMakeRect(16, y + 2, 160, 24))
        title.setStringValue_(label)
        title.setBezeled_(False)
        title.setEditable_(False)
        title.setDrawsBackground_(False)
        content.addSubview_(title)

        field = NSTextField.alloc().initWithFrame_(NSMakeRect(176, y, 372, 28))
        content.addSubview_(field)
        return field

    def show(self):
        self.window.makeKeyAndOrderFront_(None)
        NSApp.activateIgnoringOtherApps_(True)

    def close(self):
        self.window.orderOut_(None)

    def cancelClicked_(self, _sender):
        self.close()

    def applyClicked_(self, _sender):
        self.on_apply(
            self.name_field.stringValue(),
            self.command_field.stringValue(),
            self.path_field.stringValue(),
            self.workdir_field.stringValue(),
        )

    def whichClicked_(self, _sender):
        try:
            resolved = resolve_command_with_which(self.command_field.stringValue())
            self.command_field.setStringValue_(resolved)
        except ValidationError as exc:
            rumps.alert("Validation error", str(exc))


def ensure_standard_edit_menu():
    app = NSApplication.sharedApplication()
    if app is None:
        return

    main_menu = app.mainMenu()
    if main_menu is not None:
        return

    main_menu = NSMenu.alloc().initWithTitle_("MainMenu")
    edit_root = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_("Edit", None, "")
    edit_menu = NSMenu.alloc().initWithTitle_("Edit")

    cut_item = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_("Cut", "cut:", "x")
    copy_item = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_("Copy", "copy:", "c")
    paste_item = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_("Paste", "paste:", "v")
    select_all_item = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_("Select All", "selectAll:", "a")

    edit_menu.addItem_(cut_item)
    edit_menu.addItem_(copy_item)
    edit_menu.addItem_(paste_item)
    edit_menu.addItem_(NSMenuItem.separatorItem())
    edit_menu.addItem_(select_all_item)
    main_menu.addItem_(edit_root)
    main_menu.setSubmenu_forItem_(edit_menu, edit_root)
    app.setMainMenu_(main_menu)

class ServicesApp(rumps.App):
    def __init__(self):
        super().__init__("⚙️", quit_button=None)
        ensure_standard_edit_menu()
        self.add_config_window = AddConfigWindowController(self.handle_add_config_apply)
        self.refresh_menu()
        rumps.Timer(self.tick, 5).start()

    def refresh_menu(self):
        items = []
        for label in discover_service_labels():
            status = get_status(label)
            short = label.split(".")[-1]
            item = rumps.MenuItem(f"{status} {short}")

            def make_restart(lbl):
                short_name = lbl.split(".")[-1]
                def handler(_):
                    restart_service(lbl)
                return rumps.MenuItem(f"Restart {short_name}", callback=handler)

            item.add(make_restart(label))
            items.append(item)

        items.append(rumps.separator)
        items.append(rumps.MenuItem("Add Config", callback=self.open_add_config))
        items.append(rumps.separator)
        items.append(rumps.MenuItem("Quit", callback=rumps.quit_application))
        self.menu.clear()
        self.menu.update(items)

    def open_add_config(self, _):
        self.add_config_window.show()

    def handle_add_config_apply(self, name, command, path_to_start, working_directory):
        try:
            plist_path = create_launch_agent_plist(name, command, path_to_start, working_directory)
            self.add_config_window.close()
            self.refresh_menu()
            rumps.alert("Config created", plist_path)
        except ValidationError as exc:
            rumps.alert("Validation error", str(exc))
        except Exception as exc:
            rumps.alert("Failed to create config", str(exc))

    def tick(self, _):
        self.refresh_menu()

if __name__ == "__main__":
    ServicesApp().run()
