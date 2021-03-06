/*
* Copyright (C) 2010 Red Hat, Inc
* Copyright (C) 2008 William Jon McCann <jmccann@redhat.com>
* Copyright (c) 2017 elementary LLC. (https://elementary.io)
* Copyright (C) 2020 Justin Haygood <jhaygood86@gmail.com>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class About.HardwareView : Gtk.Grid {
    private bool oem_enabled;
    private string graphics;
    private string hdd;
    private string manufacturer_icon_path;
    private string manufacturer_name;
    private string manufacturer_support_url;
    private string memory;
    private string processor;
    private string product_name;
    private string product_version;
    private SystemInterface system_interface;
    private SessionManager session_manager;
    private Gtk.Label product_name_info;
    private Gtk.Entry hostname_entry;

    construct {
        try {
            session_manager = Bus.get_proxy_sync (BusType.SESSION,
                "org.gnome.SessionManager", "/org/gnome/SessionManager");
        } catch (IOError e) {
            critical (e.message);
            graphics = _("Unknown Graphics");
        }

        fetch_hardware_info ();

        try {
            system_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                "org.freedesktop.hostname1", "/org/freedesktop/hostname1");
        } catch (IOError e) {
            critical (e.message);
        }

        (system_interface as DBusProxy).g_properties_changed.connect ((changed, invalid) => {
            var host_name = changed.lookup_value ("Hostname", new VariantType ("s"));
            if (host_name != null) {
                product_name_info.label = system_interface.hostname;
            }
        });

        var manufacturer_logo = new Gtk.Image ();
        manufacturer_logo.icon_name = system_interface.icon_name;
        manufacturer_logo.hexpand = true;
        manufacturer_logo.pixel_size = 128;
        manufacturer_logo.use_fallback = true;

        product_name_info = new Gtk.Label (Environment.get_host_name ());
        product_name_info.ellipsize = Pango.EllipsizeMode.END;
        product_name_info.get_style_context ().add_class ("h2");
        product_name_info.set_selectable (true);
        product_name_info.button_press_event.connect (change_hostname);

        hostname_entry = new Gtk.Entry ();
        hostname_entry.get_style_context ().add_class ("h3");
        hostname_entry.activates_default = true;
        hostname_entry.xalign = (float) 0.5;
        hostname_entry.hexpand = true;
        hostname_entry.primary_icon_name = "user-home-symbolic";
        hostname_entry.primary_icon_tooltip_text = _("Hostname");
        hostname_entry.secondary_icon_name = "emblem-default-symbolic";
        hostname_entry.secondary_icon_tooltip_text = _("Save");
        hostname_entry.icon_press.connect (save_change);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
        size_group.add_widget (product_name_info);
        size_group.add_widget (hostname_entry);

        var processor_info = new Gtk.Label (processor);
        processor_info.justify = Gtk.Justification.CENTER;
        processor_info.ellipsize = Pango.EllipsizeMode.END;
        processor_info.margin_top = 12;
        processor_info.set_selectable (true);

        var memory_info = new Gtk.Label (_("%s memory").printf (memory));
        memory_info.ellipsize = Pango.EllipsizeMode.END;
        memory_info.set_selectable (true);

        var graphics_info = new Gtk.Label (graphics);
        graphics_info.ellipsize = Pango.EllipsizeMode.END;
        graphics_info.justify = Gtk.Justification.CENTER;
        graphics_info.set_selectable (true);

        var hdd_info = new Gtk.Label (hdd);
        hdd_info.ellipsize = Pango.EllipsizeMode.END;
        hdd_info.set_selectable (true);

        column_spacing = 6;
        row_spacing = 6;
        attach (manufacturer_logo, 0, 0, 2, 1);
        attach (processor_info, 0, 3, 2, 1);
        attach (graphics_info, 0, 4, 2, 1);
        attach (memory_info, 0, 5, 2, 1);
        attach (hdd_info, 0, 6, 2, 1);

        if (oem_enabled) {
            var fileicon = new FileIcon (File.new_for_path (manufacturer_icon_path));

            if (manufacturer_icon_path != null) {
                manufacturer_logo.icon_name = null;
                manufacturer_logo.gicon = fileicon;
            }

            var manufacturer_info = new Gtk.Label (manufacturer_name);
            manufacturer_info.ellipsize = Pango.EllipsizeMode.END;
            manufacturer_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            manufacturer_info.set_selectable (true);

            attach (manufacturer_info, 0, 2, 2, 1);

            if (product_name != null) {
                product_name_info.label = product_name;
            }

            if (product_version != null) {
                var product_version_info = new Gtk.Label ("(" + product_version + ")");
                product_version_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
                product_version_info.set_selectable (true);
                product_version_info.ellipsize = Pango.EllipsizeMode.END;
                product_version_info.xalign = 0;
                product_name_info.xalign = 1;
                attach (product_name_info, 0, 1, 1, 1);
                attach (product_version_info, 1, 1, 1, 1);
            } else {
                attach (product_name_info, 0, 1, 2, 1);
            }

            if (manufacturer_support_url != null) {
                var manufacturer_website_info = new Gtk.LinkButton.with_label (manufacturer_support_url, _("Manufacturer Website"));
                attach (manufacturer_website_info, 0, 7, 2, 1);
            }
        } else {
            attach (product_name_info, 0, 1, 2, 1);
        }
    }

    private bool change_hostname (Gdk.EventButton event) {
        if (event.button == Gdk.BUTTON_PRIMARY && event.type == Gdk.EventType.2BUTTON_PRESS) {
            remove (product_name_info);
            hostname_entry.text = system_interface.hostname;
            if (oem_enabled) {
                if (product_version != null) {
                    attach (hostname_entry, 0, 1, 1, 1);
                } else {
                    attach (hostname_entry, 0, 1, 2, 1);
                }
            } else {
                attach (hostname_entry, 0, 1, 2, 1);
            }
            hostname_entry.grab_focus ();
            show_all ();
        }
        return Gdk.EVENT_PROPAGATE;
    }

    private void save_change (Gtk.EntryIconPosition pos, Gdk.Event event) {
        if (pos == Gtk.EntryIconPosition.SECONDARY) {
            try {
                system_interface.set_static_hostname (hostname_entry.text, true);
            } catch (Error e) {
                warning (e.message);
            }
            remove (hostname_entry);
            if (oem_enabled) {
                if (product_version != null) {
                    attach (product_name_info, 0, 1, 1, 1);
                } else {
                    attach (product_name_info, 0, 1, 2, 1);
                }
            } else {
                attach (product_name_info, 0, 1, 2, 1);
            }
            show_all ();
        }
    }

    private string? try_get_arm_model (GLib.HashTable<string, string> values) {
        string? cpu_implementer = values.lookup ("CPU implementer");
        string? cpu_part = values.lookup ("CPU part");

        if (cpu_implementer == null || cpu_part == null) {
            return null;
        }

        return ARMPartDecoder.decode_arm_model (cpu_implementer, cpu_part);
    }

    private string? get_cpu_info () {
        unowned GLibTop.sysinfo? info = GLibTop.get_sysinfo ();

        if (info == null) {
            return null;
        }

        var counts = new Gee.HashMap<string, uint> ();
        const string[] KEYS = { "model name", "cpu", "Processor" };

        for (int i = 0; i < info.ncpu; i++) {
            unowned GLib.HashTable<string, string> values = info.cpuinfo[i].values;
            string? model = null;
            foreach (var key in KEYS) {
                model = values.lookup (key);

                if (model != null) {
                    break;
                }
            }

            if (model == null) {
                model = try_get_arm_model (values);
                if (model == null) {
                    continue;
                }
            }

            string? core_count = values.lookup ("cpu cores");
            if (core_count != null) {
                counts.@set (model, uint.parse (core_count));
                continue;
            }

            if (!counts.has_key (model)) {
                counts.@set (model, 1);
            } else {
                counts.@set (model, counts.@get (model) + 1);
            }
        }

        if (counts.size == 0) {
            return null;
        }

        string result = "";
        foreach (var cpu in counts.entries) {
            if (result.length > 0) {
                result += "\n";
            }

            if (cpu.@value == 2) {
                result += _("Dual-Core %s").printf (clean_name (cpu.key));
            } else if (cpu.@value == 4) {
                result += _("Quad-Core %s").printf (clean_name (cpu.key));
            } else if (cpu.@value == 6) {
                result += _("Hexa-Core %s").printf (clean_name (cpu.key));
            } else {
                result += "%u\u00D7 %s ".printf (cpu.@value, clean_name (cpu.key));
            }
        }

        return result;
    }

    private void fetch_hardware_info () {
        string? cpu = get_cpu_info ();

        if (cpu == null) {
            processor = _("Unknown Processor");
        } else {
            processor = cpu;
        }

        // Memory
        GLibTop.mem mem;
        GLibTop.get_mem (out mem);
        memory = GLib.format_size (mem.total);

        // Graphics
        graphics = clean_name (session_manager.renderer);

        // Hard Drive
        var file_root = GLib.File.new_for_path ("/");
        string storage_capacity = "";
        try {
            var info = file_root.query_filesystem_info (GLib.FileAttribute.FILESYSTEM_SIZE, null);
            storage_capacity = GLib.format_size (info.get_attribute_uint64 (GLib.FileAttribute.FILESYSTEM_SIZE));
        } catch (Error e) {
            critical (e.message);
            storage_capacity = _("Unknown");
        }

        hdd = get_storage_type (storage_capacity);

        try {
            var oem_file = new KeyFile ();
            oem_file.load_from_file ("/etc/oem.conf", KeyFileFlags.NONE);
            // Assume we get the manufacturer name
            manufacturer_name = oem_file.get_string ("OEM", "Manufacturer");

            // We need to check if the key is here because get_string throws an error if the key isn't available.
            if (oem_file.has_key ("OEM", "Product")) {
                product_name = oem_file.get_string ("OEM", "Product");
            }

            if (oem_file.has_key ("OEM", "Version")) {
                product_version = oem_file.get_string ("OEM", "Version");
            }

            if (oem_file.has_key ("OEM", "Logo")) {
                manufacturer_icon_path = oem_file.get_string ("OEM", "Logo");
            }

            if (oem_file.has_key ("OEM", "URL")) {
                manufacturer_support_url = oem_file.get_string ("OEM", "URL");
            }

            oem_enabled = true;
        } catch (Error e) {
            debug (e.message);
            oem_enabled = false;
        }
    }

    private string clean_name (string info) {

        string pretty = GLib.Markup.escape_text (info).strip ();

        const GraphicsReplaceStrings REPLACE_STRINGS[] = {
            { "Mesa DRI ", ""},
            { "[(]R[)]", "®"},
            { "[(]TM[)]", "™"},
            { "Gallium .* on (AMD .*)", "\\1"},
            { "(AMD .*) [(].*", "\\1"},
            { "(AMD [A-Z])(.*)", "\\1\\L\\2\\E"},
            { "Graphics Controller", "Graphics"},
        };

        try {
            foreach (GraphicsReplaceStrings replace_string in REPLACE_STRINGS) {
                GLib.Regex re = new GLib.Regex (replace_string.regex, 0, 0);
                pretty = re.replace (pretty, -1, 0, replace_string.replacement, 0);
            }
        } catch (Error e) {
            critical ("Couldn't cleanup vendor string: %s", e.message);
        }

        return pretty;
    }

    private string get_storage_type (string storage_capacity) {
        string partition_name = get_partition_name ();
        string disk_name = get_disk_name (partition_name);
        string path = "/sys/block/%s/queue/rotational".printf (disk_name);
        string storage = "";
        try {
            string contents;
            FileUtils.get_contents (path, out contents);
            if (int.parse (contents) == 0) {
                if (disk_name.has_prefix ("nvme")) {
                    storage = _("%s storage (NVMe SSD)").printf (storage_capacity);
                } else if (disk_name.has_prefix ("mmc")) {
                    storage = _("%s storage (eMMC)").printf (storage_capacity);
                } else {
                    storage = _("%s storage (SATA SSD)").printf (storage_capacity);
                }
            } else {
                storage = _("%s storage (HDD)").printf (storage_capacity);
            }
        } catch (FileError e) {
            warning (e.message);
            // Set fallback string for the device type
            storage = _("%s storage").printf (storage_capacity);
        }
        return storage;
    }

    private string get_partition_name () {
        string df_stdout;
        string partition = "";
        try {
            Process.spawn_command_line_sync ("df /",
                out df_stdout);
            string[] output = df_stdout.split ("\n");
            foreach (string line in output) {
                if (line.has_prefix ("/dev/")) {
                    int idx = line.index_of (" ");
                    if (idx != -1) {
                        partition = line.substring (0, idx);
                        return partition;
                    }
                }
            }
        } catch (Error e) {
            warning (e.message);
        }
        return partition;
    }

    private string get_disk_name (string partition) {
        string lsblk_stout;
        string disk_name = "";
        string command = "lsblk -no pkname " + partition;
        try {
            Process.spawn_command_line_sync (command,
                out lsblk_stout);
            disk_name = lsblk_stout.strip ();
        } catch (Error e) {
            warning (e.message);
        }
        return disk_name;
    }

    struct GraphicsReplaceStrings {
        string regex;
        string replacement;
    }
}

[DBus (name = "org.freedesktop.hostname1")]
public interface SystemInterface : Object {
    [DBus (name = "IconName")]
    public abstract string icon_name { owned get; }
    public abstract string hostname { owned get; }
    public abstract void set_static_hostname (string arg0, bool arg1) throws Error;
}

[DBus (name = "org.gnome.SessionManager")]
public interface SessionManager : Object {
    [DBus (name = "Renderer")]
    public abstract string renderer { owned get;}
}
