# Android Linux Terminal (`images.tar.gz`) & Tart VM

`infra/android` builds a custom, pre-provisioned Debian `aarch64` image archive (`images.tar.gz`) compatible with Android's built-in **Linux Terminal** app (`com.android.virtualization.terminal` on Android Virtualization Framework / AVF), as well as a bootable GPT raw disk image (`disk.img`) that runs directly in **Tart** on Apple Silicon macOS.

## How It Works

1. Fetches Google's upstream AVF Debian `aarch64` archive (`https://dl.google.com/android/ferrochrome/latest/aarch64/images.tar.gz`), preserving the official kernel, `efi_part`, `vm_config.json`, `build_id`, and AVF guest daemons (`ttyd`, `forwarder_guest_launcher`, `storage_balloon_agent`, `shutdown_runner`).
2. Expands and loop-mounts `root_part` (ext4).
3. Installs Ansible, Linuxbrew (`/home/linuxbrew/.linuxbrew`), Ansible Galaxy requirements, and the `scripts/formula-intersection` warm packages under the default `droid` user (plus `openssh-server` and `virtio-net` DHCP fallback for Tart VM).
4. Runs `env-setup` playbooks (`01-config`, `02-cli`, `04-packages`, `05-repos`, `07-cloud`, `08-prefs`) for the chosen config preset (`none`, `mini`, `default`, or `most`).
5. Shrinks the ext4 filesystem (`resize2fs -M` + headroom) and packages a sparse `images.tar.gz` (plus an optional GPT `disk.img` for Tart).

## Building & Running Locally with Tart (macOS Apple Silicon)

You can use your existing Tart `ubuntu` VM to build `images.tar.gz` and import the resulting Android Debian image as a local `debian-android` Tart VM:

```bash
# 1. Ensure the Tart Linux builder VM is running
env-setup vm create linux
env-setup vm start ubuntu

# 2. Build images.tar.gz (and import as 'debian-android' Tart VM)
env-setup vm android build --config default --import

# 3. Boot and SSH into the custom Android Debian image locally in Tart
env-setup vm start debian-android
env-setup vm ssh debian-android
```

## Building Directly on an `aarch64` Linux Host

```bash
sudo ./infra/android/build-image.sh \
  --config default \
  --output images.tar.gz \
  --tart-disk disk.img
```

## Installing on an Android Device

> **Note:** Android's stock Terminal app checks `/sdcard/linux/images.tar.gz` during initial setup on `userdebug`/`eng` builds or custom AVF terminal forks.

1. Download `android-default-images.tar.gz` from GitHub Releases/Actions (or build `images.tar.gz` locally).
2. Connect your Android device with USB debugging enabled and push the archive:
   ```bash
   env-setup vm android push images.tar.gz
   # or directly:
   ./infra/android/push-image.sh images.tar.gz
   ```
3. If the Linux Terminal app was previously set up, clear its storage (`adb shell pm clear com.android.virtualization.terminal`), then launch the **Terminal** app. It will automatically ingest `/sdcard/linux/images.tar.gz`.
