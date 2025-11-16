#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import frida
import argparse
import os
import sys
import time
import json

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 27042
DEFAULT_LOG = "frida_hook_log.json"

def on_message_factory(log_file):
    def on_message(message, data):
        try:
            mtype = message.get("type")
            if mtype == "send":
                payload = message.get("payload")
                # Console display
                print(f"[JS] {json.dumps(payload, ensure_ascii=False)}")
                # JSONL write
                with open(log_file, "a", encoding="utf-8") as f:
                    f.write(json.dumps(payload, ensure_ascii=False) + "\n")
            elif mtype == "error":
                # Print stack if present
                stack = message.get("stack")
                if stack:
                    print(f"[JS ERROR]\n{stack}")
                else:
                    print(f"[JS ERROR] {message}")
            else:
                print(f"[MSG] {message}")
        except Exception as e:
            print(f"[PY ERROR] handling message: {e}")
    return on_message

def connect_to_gadget(host, port, timeout_sec=5.0):
    address = f"{host}:{port}"
    dm = frida.get_device_manager()
    deadline = time.time() + timeout_sec
    last_exc = None
    while time.time() < deadline:
        try:
            dev = dm.add_remote_device(address)
            return dev
        except Exception as e:
            last_exc = e
            time.sleep(0.25)
    raise last_exc or RuntimeError(f"Unable to connect to {address}")

def choose_target_process(dev, target):
    procs = dev.enumerate_processes()
    if target:
        # if target is a pid
        if target.isdigit():
            pid = int(target)
            for p in procs:
                if p.pid == pid:
                    return p
            raise RuntimeError(f"PID {pid} not found on the remote device.")
        # otherwise match by name (substring)
        matches = [p for p in procs if target.lower() in p.name.lower()]
        if len(matches) == 1:
            return matches[0]
        if len(matches) > 1:
            # Prioritize exact match
            for p in matches:
                if p.name.lower() == target.lower():
                    return p
            return matches[0]
        raise RuntimeError(f"No process matching '{target}' found.")
    else:
        # No target given: prefer a process different from "Gadget" if possible
        non_gadget = [p for p in procs if p.name.lower() != "gadget"]
        if non_gadget:
            return non_gadget[0]
        # otherwise return Gadget if present
        for p in procs:
            if p.name.lower() == "gadget":
                return p
        raise RuntimeError("No available process to attach to on the remote device.")

def main():
    parser = argparse.ArgumentParser(description="Load a Frida script via Frida Gadget (simplified loader)")
    parser.add_argument("-H", "--host", default=DEFAULT_HOST, help="Gadget address (default: 127.0.0.1)")
    parser.add_argument("-P", "--port", type=int, default=DEFAULT_PORT, help="Gadget port (default: 27042)")
    parser.add_argument("-s", "--script", default="hook.js", help="Path to the JS script to inject (default: hook.js)")
    parser.add_argument("-l", "--log", default=DEFAULT_LOG, help=f"JSONL log file (default: {DEFAULT_LOG})")
    parser.add_argument("--resume", action="store_true", help="Call device.resume(pid) after loading (useful if on_load:'wait')")
    parser.add_argument("--timeout", type=float, default=30.0, help="Gadget connection timeout in seconds (default: 30s)")
    parser.add_argument("-t", "--target", default=None, help="Name (or pid) of the target process. If omitted, automatic selection.")
    args = parser.parse_args()

    if not os.path.isfile(args.script):
        print(f"[!] JS script not found: {args.script}")
        sys.exit(1)

    # reset log
    try:
        open(args.log, "w", encoding="utf-8").close()
    except Exception as e:
        print(f"[!] Unable to initialize log '{args.log}': {e}")
        sys.exit(1)

    print(f"[*] Connecting to Gadget at {args.host}:{args.port} ...")
    try:
        dev = connect_to_gadget(args.host, args.port, args.timeout)
    except Exception as e:
        print(f"[❌] Connection failed: {e}")
        sys.exit(1)

    session = None
    script = None
    try:
        proc = choose_target_process(dev, args.target)
        print(f"[OK] Selected process: pid={proc.pid} name={proc.name}")

        print("[*] Attach ...")
        session = dev.attach(proc.pid)

        with open(args.script, "r", encoding="utf-8") as f:
            code = f.read()

        script = session.create_script(code)
        script.on("message", on_message_factory(os.path.abspath(args.log)))
        script.load()
        print(f"[OK] Script loaded: {args.script}")

        if args.resume:
            try:
                # some devices may not support resume; ignore non-fatal errors
                dev.resume(proc.pid)
                print("[OK] Process resumed (resume).")
            except Exception as e:
                print(f"[i] resume() not supported or failed: {e}")

        print(f"[📄] Logs -> {os.path.abspath(args.log)}")
        print("[⏳] Ctrl+C to quit.")
        try:
            while True:
                time.sleep(0.2)
        except KeyboardInterrupt:
            pass

    except Exception as e:
        print(f"[❌] Error: {e}")
    finally:
        try:
            if script is not None:
                script.unload()
        except Exception:
            pass
        try:
            if session is not None:
                session.detach()
        except Exception:
            pass
        print("[*] Done.")

if __name__ == "__main__":
    main()
