// Copyright 2021 Sony Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter_window.h"

#include <chrono>
#include <cmath>
#include <iostream>
#include <thread>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <iomanip>
#include <sstream>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(
    const flutter::FlutterViewController::ViewProperties view_properties,
    const flutter::DartProject project)
    : view_properties_(view_properties), project_(project) {}

bool FlutterWindow::OnCreate()
{
  flutter_view_controller_ = std::make_unique<flutter::FlutterViewController>(
      view_properties_, project_);

  // Ensure that basic setup of the controller was successful.
  if (!flutter_view_controller_->engine() ||
      !flutter_view_controller_->view())
  {
    return false;
  }

  // Register Flutter plugins.
  RegisterPlugins(flutter_view_controller_->engine());

  SetupAlarmChannel(flutter_view_controller_->engine()->messenger());

  return true;
}

void FlutterWindow::SetupAlarmChannel(flutter::BinaryMessenger *messenger)
{
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.example.clock/alarm",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler([](const auto &call, auto result)
                                {
    if (call.method_name() == "setAlarm") {
      const auto *arguments = std::get_if<flutter::EncodableMap>(call.arguments());
      if (!arguments)
      {
        result->Error("bad_args", "Expected map");
        return;
      }

      auto id_it = arguments->find(flutter::EncodableValue("id"));
      auto ts_it = arguments->find(flutter::EncodableValue("timestamp"));
      auto rd_it = arguments->find(flutter::EncodableValue("repeatDays"));
      auto snooze_it = arguments->find(flutter::EncodableValue("isSnoozeEnabled"));
      bool is_snooze_enabled = std::get<bool>(snooze_it->second);

      std::cout << "IS SNOOZE ENABLED: " << is_snooze_enabled << std::endl;

      if (id_it == arguments->end() || ts_it == arguments->end() || rd_it == arguments->end())
      {
        result->Error("missing_args", "Missing required arguments");
        return;
      }

      std::string id = std::get<std::string>(id_it->second);
      int64_t timestamp = std::get<int64_t>(ts_it->second);

      // Correct way to handle EncodableList
      std::vector<int> repeat_days;
      if (const auto *list = std::get_if<flutter::EncodableList>(&rd_it->second))
      {
        for (const auto &item : *list)
        {
          if (const auto *val = std::get_if<int32_t>(&item))
          {
            repeat_days.push_back(*val);
          }
          else if (const auto *val_int64 = std::get_if<int64_t>(&item))
          {
            repeat_days.push_back(static_cast<int>(*val_int64));
          }
        }
      }

      // Convert timestamp to time parts
      std::time_t t = timestamp / 1000;
      std::tm *tm = std::localtime(&t);
      char time_buf[10];
      std::strftime(time_buf, sizeof(time_buf), "%H:%M:%S", tm);
      std::string hms = time_buf;
      std::string calendar_spec;
      if (repeat_days.empty())
      {
        char date_buf[20];
        std::strftime(date_buf, sizeof(date_buf), "%Y-%m-%d %H:%M:%S", tm);
        calendar_spec = date_buf;
      }
      else
      {
        std::string days_str = "";
        const char *day_names[] = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
        for (size_t i = 0; i < repeat_days.size(); ++i)
        {
          int day_idx = repeat_days[i];
          if (day_idx >= 0 && day_idx < 7)
          {
            if (!days_str.empty())
              days_str += ",";
            days_str += day_names[day_idx];
          }
        }
        calendar_spec = days_str + " *-*-* " + hms;
      }

      std::string alarm_command =
          "systemd-run --user --unit=alarm-" + id + " --on-calendar=\"" + calendar_spec +
          "\" /bin/bash -c \"/usr/bin/notify-send 'Alarm' 'Time to wake up!' --icon=alarm-clock && /usr/bin/aplay /usr/share/sounds/alsa/Front_Center.wav\"";

      std::cout << "Executing: " << alarm_command << std::endl;
      int status = system(alarm_command.c_str());

      if (status == 0) {
        result->Success();
      } else {
        result->Error("failed_to_set", "Failed to execute systemd-run");
      }
    } else if (call.method_name() == "cancelAlarm") {
      const auto* arguments =
          std::get_if<flutter::EncodableMap>(call.arguments());
      auto id = std::get<std::string>(
          arguments->at(flutter::EncodableValue("id")));

      std::string command = "systemctl --user stop alarm-" + id + ".timer || true";
      std::cout << "Executing: " << command << std::endl;
      system(command.c_str());
      result->Success();
    } else if (call.method_name() == "setTimer") {
      const auto *arguments = std::get_if<flutter::EncodableMap>(call.arguments());
      if (!arguments) {
        result->Error("bad_args", "Expected map");
        return;
      }
      auto id_it = arguments->find(flutter::EncodableValue("id"));
      auto dur_it = arguments->find(flutter::EncodableValue("durationSec"));
      if (id_it == arguments->end() || dur_it == arguments->end()) {
        result->Error("missing_args", "Missing required arguments");
        return;
      }
      std::string id = std::get<std::string>(id_it->second);
      int64_t dur_val = 0;
      if (const auto *val_int32 = std::get_if<int32_t>(&dur_it->second)) {
        dur_val = *val_int32;
      } else if (const auto *val_int64 = std::get_if<int64_t>(&dur_it->second)) {
        dur_val = *val_int64;
      }

      std::string timer_command =
          "systemd-run --user --unit=timer-" + id + " --on-active=" + std::to_string(dur_val) +
          " /bin/bash -c \"/usr/bin/notify-send 'Timer' 'Timer finished!' --icon=alarm-clock && /usr/bin/aplay /usr/share/sounds/alsa/Front_Center.wav\"";

      std::cout << "Executing: " << timer_command << std::endl;
      int status = system(timer_command.c_str());
      if (status == 0) {
        result->Success();
      } else {
        result->Error("failed_to_set", "Failed to execute systemd-run");
      }
    } else if (call.method_name() == "cancelTimer") {
      const auto *arguments = std::get_if<flutter::EncodableMap>(call.arguments());
      if (!arguments) {
        result->Error("bad_args", "Expected map");
        return;
      }
      auto id_it = arguments->find(flutter::EncodableValue("id"));
      if (id_it == arguments->end()) {
        result->Error("missing_args", "Missing required arguments");
        return;
      }
      std::string id = std::get<std::string>(id_it->second);
      std::string command = "systemctl --user stop timer-" + id + ".timer || true";
      std::cout << "Executing: " << command << std::endl;
      system(command.c_str());
      result->Success();
    } else if (call.method_name() == "playCompletionSound") {
      std::string command = "/usr/bin/aplay /usr/share/sounds/alsa/Front_Center.wav &";
      system(command.c_str());
      result->Success();
    } else {
      result->NotImplemented();
    } 
  });
}

void FlutterWindow::OnDestroy()
{
  if (flutter_view_controller_)
  {
    flutter_view_controller_ = nullptr;
  }
}

void FlutterWindow::Run()
{
  // Main loop.
  auto next_flutter_event_time =
      std::chrono::steady_clock::time_point::clock::now();
  while (flutter_view_controller_->view()->DispatchEvent())
  {
    // Wait until the next event.
    {
      auto wait_duration =
          std::max(std::chrono::nanoseconds(0),
                   next_flutter_event_time -
                       std::chrono::steady_clock::time_point::clock::now());
      std::this_thread::sleep_for(
          std::chrono::duration_cast<std::chrono::milliseconds>(wait_duration));
    }

    // Processes any pending events in the Flutter engine, and returns the
    // number of nanoseconds until the next scheduled event (or max, if none).
    auto wait_duration = flutter_view_controller_->engine()->ProcessMessages();
    {
      auto next_event_time = std::chrono::steady_clock::time_point::max();
      if (wait_duration != std::chrono::nanoseconds::max())
      {
        next_event_time =
            std::min(next_event_time,
                     std::chrono::steady_clock::time_point::clock::now() +
                         wait_duration);
      }
      else
      {
        // Wait for the next frame if no events.
        auto frame_rate = flutter_view_controller_->view()->GetFrameRate();
        next_event_time = std::min(
            next_event_time,
            std::chrono::steady_clock::time_point::clock::now() +
                std::chrono::milliseconds(
                    static_cast<int>(std::trunc(1000000.0 / frame_rate))));
      }
      next_flutter_event_time =
          std::max(next_flutter_event_time, next_event_time);
    }
  }
}
