import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import session_to_events


def build_fixture_records():
    return [
        {
            "type": "user",
            "timestamp": "2026-09-12T00:00:01Z",
            "message": {"content": "Please add the feature."},
        },
        {
            "type": "assistant",
            "timestamp": "2026-09-12T00:00:02Z",
            "message": {
                "model": "claude-fable-5-1",
                "content": [{"type": "text", "text": "Starting."}],
            },
        },
        {
            "type": "assistant",
            "timestamp": "2026-09-12T00:00:03Z",
            "message": {
                "model": "claude-fable-5-1",
                "content": [
                    {
                        "type": "tool_use",
                        "id": "toolu_S1",
                        "name": "Skill",
                        "input": {"skill": "honesty"},
                    }
                ],
            },
        },
        {
            "type": "assistant",
            "timestamp": "2026-09-12T00:00:04Z",
            "message": {
                "model": "claude-fable-5-1",
                "content": [
                    {
                        "type": "tool_use",
                        "id": "toolu_A1",
                        "name": "Agent",
                        "input": {
                            "subagent_type": "implementer",
                            "model": "sonnet",
                            "description": "impl",
                        },
                    }
                ],
            },
        },
        {
            "type": "user",
            "timestamp": "2026-09-12T00:00:05Z",
            "message": {
                "content": [
                    {
                        "type": "tool_result",
                        "tool_use_id": "toolu_A1",
                        "content": "STATUS: BLOCKED\nmissing file",
                    }
                ]
            },
        },
        {
            "type": "assistant",
            "timestamp": "2026-09-12T00:00:06Z",
            "message": {
                "model": "claude-fable-5-1",
                "content": [{"type": "text", "text": "The implementer is blocked."}],
            },
        },
        {
            "type": "assistant",
            "timestamp": "2026-09-12T00:00:07Z",
            "message": {
                "model": "<synthetic>",
                "content": [{"type": "text", "text": "You've hit your session limit"}],
            },
        },
        {
            "type": "assistant",
            "timestamp": "2026-09-12T00:00:08Z",
            "message": {
                "model": "claude-fable-5-1",
                "content": [
                    {
                        "type": "tool_use",
                        "id": "toolu_A2",
                        "name": "Agent",
                        "input": {"description": "bg"},
                    }
                ],
            },
        },
        {
            "type": "user",
            "timestamp": "2026-09-12T00:00:09Z",
            "message": {
                "content": [
                    {
                        "type": "tool_result",
                        "tool_use_id": "toolu_A2",
                        "content": [
                            {
                                "type": "text",
                                "text": "Async agent launched successfully. (internal)",
                            }
                        ],
                    }
                ]
            },
        },
        {
            "type": "user",
            "timestamp": "2026-09-12T00:00:10Z",
            "message": {
                "content": (
                    "<task-notification>\n"
                    "<task-id>abc</task-id>\n"
                    "<tool-use-id>toolu_A2</tool-use-id>\n"
                    "<status>completed</status>\n"
                    "<result>VERDICT: PASS</result>\n"
                    "</task-notification>"
                )
            },
        },
        {
            "type": "assistant",
            "timestamp": "2026-09-12T00:00:11Z",
            "message": {
                "model": "claude-fable-5-1",
                "content": [{"type": "thinking", "thinking": "..."}],
            },
        },
        {
            "type": "assistant",
            "timestamp": "2026-09-12T00:00:12Z",
            "message": {
                "model": "claude-fable-5-1",
                "content": [
                    {
                        "type": "tool_use",
                        "id": "toolu_B1",
                        "name": "Bash",
                        "input": {"command": "ls"},
                    }
                ],
            },
        },
        {
            "type": "user",
            "timestamp": "2026-09-12T00:00:13Z",
            "message": {
                "content": [
                    {"type": "text", "text": "Base directory for this skill: x"}
                ]
            },
        },
        {"type": "attachment", "timestamp": "2026-09-12T00:00:14Z"},
    ]


EXPECTED_FIXTURE_EVENT_SEQUENCE = [
    "user.message",
    "assistant.message",
    "skill.invoked",
    "subagent.started",
    "subagent.completed",
    "assistant.message",
    "assistant.message",
    "subagent.started",
    "subagent.completed",
]

FIXTURE_RECORD_COUNT = 14
FIXTURE_EVENT_COUNT = 9


def write_temp_jsonl(lines):
    handle = tempfile.NamedTemporaryFile(
        mode="w", suffix=".jsonl", delete=False, encoding="utf-8"
    )
    with handle:
        handle.write("\n".join(lines) + "\n")
    return handle.name


class ConvertRecordsTests(unittest.TestCase):
    def test_ConvertRecords_UserStringContent_EmitsUserMessage(self):
        # Arrange
        user_text = "Please add the feature."
        records = [{"type": "user", "timestamp": "t1", "message": {"content": user_text}}]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        expected_event = {"ts": "t1", "event": "user.message", "text": user_text}
        self.assertEqual([expected_event], events)

    def test_ConvertRecords_AssistantTextBlock_CarriesModelAndText(self):
        # Arrange
        model_name = "claude-fable-5-1"
        text = "Starting."
        records = [
            {
                "type": "assistant",
                "timestamp": "t2",
                "message": {"model": model_name, "content": [{"type": "text", "text": text}]},
            }
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        expected_event = {
            "ts": "t2",
            "event": "assistant.message",
            "model": model_name,
            "text": text,
        }
        self.assertEqual([expected_event], events)

    def test_ConvertRecords_SyntheticModel_PreservesLiteral(self):
        # Arrange
        synthetic_model = "<synthetic>"
        records = [
            {
                "type": "assistant",
                "timestamp": "t7",
                "message": {
                    "model": synthetic_model,
                    "content": [{"type": "text", "text": "You've hit your session limit"}],
                },
            }
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        self.assertEqual(synthetic_model, events[0]["model"])

    def test_ConvertRecords_AssistantNullContent_EmitsNoEvent(self):
        # Arrange
        records = [
            {
                "type": "assistant",
                "timestamp": "t1",
                "message": {"model": "x", "content": None},
            }
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        expected_events = []
        self.assertEqual(expected_events, events)

    def test_ConvertRecords_SkillToolUse_EmitsSkillInvoked(self):
        # Arrange
        skill_name = "honesty"
        records = [
            {
                "type": "assistant",
                "timestamp": "t3",
                "message": {
                    "model": "claude-fable-5-1",
                    "content": [
                        {
                            "type": "tool_use",
                            "id": "toolu_S1",
                            "name": "Skill",
                            "input": {"skill": skill_name},
                        }
                    ],
                },
            }
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        expected_event = {"ts": "t3", "event": "skill.invoked", "skill": skill_name}
        self.assertEqual([expected_event], events)

    def test_ConvertRecords_AgentToolUseWithModel_EmitsSubagentStartedWithModel(self):
        # Arrange
        agent_type = "implementer"
        model_name = "sonnet"
        tool_use_id = "toolu_A1"
        records = [
            {
                "type": "assistant",
                "timestamp": "t4",
                "message": {
                    "model": "claude-fable-5-1",
                    "content": [
                        {
                            "type": "tool_use",
                            "id": tool_use_id,
                            "name": "Agent",
                            "input": {
                                "subagent_type": agent_type,
                                "model": model_name,
                                "description": "impl",
                            },
                        }
                    ],
                },
            }
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        expected_event = {
            "ts": "t4",
            "event": "subagent.started",
            "tool_use_id": tool_use_id,
            "agent_type": agent_type,
            "model": model_name,
        }
        self.assertEqual([expected_event], events)

    def test_ConvertRecords_AgentToolUseWithoutTypeOrModel_DefaultsToGeneralPurposeAndInherit(
        self,
    ):
        # Arrange
        default_agent_type = "general-purpose"
        default_model = "inherit"
        tool_use_id = "toolu_A2"
        records = [
            {
                "type": "assistant",
                "timestamp": "t8",
                "message": {
                    "model": "claude-fable-5-1",
                    "content": [
                        {
                            "type": "tool_use",
                            "id": tool_use_id,
                            "name": "Agent",
                            "input": {"description": "bg"},
                        }
                    ],
                },
            }
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        self.assertEqual(default_agent_type, events[0]["agent_type"])
        self.assertEqual(default_model, events[0]["model"])

    def test_ConvertRecords_ToolResultForAgent_EmitsSubagentCompletedWithText(self):
        # Arrange
        tool_use_id = "toolu_A1"
        result_text = "STATUS: BLOCKED\nmissing file"
        records = [
            {
                "type": "assistant",
                "timestamp": "t4",
                "message": {
                    "model": "claude-fable-5-1",
                    "content": [
                        {
                            "type": "tool_use",
                            "id": tool_use_id,
                            "name": "Agent",
                            "input": {"subagent_type": "implementer", "model": "sonnet"},
                        }
                    ],
                },
            },
            {
                "type": "user",
                "timestamp": "t5",
                "message": {
                    "content": [
                        {
                            "type": "tool_result",
                            "tool_use_id": tool_use_id,
                            "content": result_text,
                        }
                    ]
                },
            },
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        completed_event = events[1]
        expected_event = {
            "ts": "t5",
            "event": "subagent.completed",
            "tool_use_id": tool_use_id,
            "text": result_text,
        }
        self.assertEqual(expected_event, completed_event)

    def test_ConvertRecords_ToolResultForNonAgentTool_EmitsNoEvent(self):
        # Arrange
        non_agent_tool_use_id = "toolu_B9"
        records = [
            {
                "type": "assistant",
                "timestamp": "t4",
                "message": {
                    "model": "claude-fable-5-1",
                    "content": [
                        {
                            "type": "tool_use",
                            "id": non_agent_tool_use_id,
                            "name": "Bash",
                            "input": {"command": "ls"},
                        }
                    ],
                },
            },
            {
                "type": "user",
                "timestamp": "t5",
                "message": {
                    "content": [
                        {
                            "type": "tool_result",
                            "tool_use_id": non_agent_tool_use_id,
                            "content": "file list",
                        }
                    ]
                },
            },
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        expected_events = []
        self.assertEqual(expected_events, events)

    def test_ConvertRecords_LaunchAcknowledgment_EmitsNoEvent(self):
        # Arrange
        tool_use_id = "toolu_A2"
        expected_remaining_event = "subagent.started"
        records = [
            {
                "type": "assistant",
                "timestamp": "t8",
                "message": {
                    "model": "claude-fable-5-1",
                    "content": [
                        {
                            "type": "tool_use",
                            "id": tool_use_id,
                            "name": "Agent",
                            "input": {"description": "bg"},
                        }
                    ],
                },
            },
            {
                "type": "user",
                "timestamp": "t9",
                "message": {
                    "content": [
                        {
                            "type": "tool_result",
                            "tool_use_id": tool_use_id,
                            "content": [
                                {
                                    "type": "text",
                                    "text": "Async agent launched successfully. (internal)",
                                }
                            ],
                        }
                    ]
                },
            },
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        expected_event_count = 1
        self.assertEqual(expected_event_count, len(events))
        self.assertEqual(expected_remaining_event, events[0]["event"])

    def test_ConvertRecords_TaskNotification_EmitsSubagentCompletedWithToolUseId(self):
        # Arrange
        tool_use_id = "toolu_A2"
        notification_text = (
            "<task-notification>\n"
            "<task-id>abc</task-id>\n"
            "<tool-use-id>toolu_A2</tool-use-id>\n"
            "<status>completed</status>\n"
            "<result>VERDICT: PASS</result>\n"
            "</task-notification>"
        )
        records = [
            {"type": "user", "timestamp": "t10", "message": {"content": notification_text}}
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        expected_event = {
            "ts": "t10",
            "event": "subagent.completed",
            "tool_use_id": tool_use_id,
            "text": notification_text,
        }
        self.assertEqual([expected_event], events)

    def test_ConvertRecords_ThinkingOtherToolUseAndHookText_EmitNoEvent(self):
        # Arrange
        records = [
            {
                "type": "assistant",
                "timestamp": "t11",
                "message": {
                    "model": "claude-fable-5-1",
                    "content": [{"type": "thinking", "thinking": "..."}],
                },
            },
            {
                "type": "assistant",
                "timestamp": "t12",
                "message": {
                    "model": "claude-fable-5-1",
                    "content": [
                        {
                            "type": "tool_use",
                            "id": "toolu_B1",
                            "name": "Bash",
                            "input": {"command": "ls"},
                        }
                    ],
                },
            },
            {
                "type": "user",
                "timestamp": "t13",
                "message": {
                    "content": [
                        {"type": "text", "text": "Base directory for this skill: x"}
                    ]
                },
            },
        ]

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        expected_events = []
        self.assertEqual(expected_events, events)

    def test_ConvertRecords_TextLongerThanMax_TruncatesToMax(self):
        # Arrange
        max_text = 5
        long_text = "abcdefghij"
        records = [{"type": "user", "timestamp": "t1", "message": {"content": long_text}}]

        # Act
        events = session_to_events.convert_records(records, max_text=max_text)

        # Assert
        expected_text = "abcde"
        self.assertEqual(expected_text, events[0]["text"])

    def test_ConvertRecords_FullFixture_EventSequenceMatches(self):
        # Arrange
        records = build_fixture_records()

        # Act
        events = session_to_events.convert_records(records)

        # Assert
        self.assertEqual(FIXTURE_RECORD_COUNT, len(records))
        self.assertEqual(FIXTURE_EVENT_COUNT, len(events))
        self.assertEqual(
            EXPECTED_FIXTURE_EVENT_SEQUENCE, [event["event"] for event in events]
        )


class ReadRecordsTests(unittest.TestCase):
    def test_ReadRecords_MalformedLine_RaisesValueErrorNamingLineNumber(self):
        # Arrange
        malformed_line_number = 2
        lines = ['{"type": "user"}', "{not valid json", '{"type": "assistant"}']
        path = write_temp_jsonl(lines)

        # Act / Assert
        try:
            with self.assertRaises(ValueError) as raised:
                session_to_events.read_records(path)
            self.assertIn(str(malformed_line_number), str(raised.exception))
        finally:
            os.remove(path)


class MainTests(unittest.TestCase):
    def test_Main_WithOutPath_WritesOneJsonObjectPerEvent(self):
        # Arrange
        records = build_fixture_records()
        transcript_lines = [json.dumps(record) for record in records]
        transcript_path = write_temp_jsonl(transcript_lines)
        out_handle = tempfile.NamedTemporaryFile(suffix=".jsonl", delete=False)
        out_handle.close()
        out_path = out_handle.name

        # Act
        try:
            exit_code = session_to_events.main([transcript_path, "--out", out_path])
            with open(out_path, "r", encoding="utf-8") as f:
                lines = [line for line in f.read().split("\n") if line.strip()]
        finally:
            os.remove(transcript_path)
            os.remove(out_path)

        # Assert
        expected_exit_code = 0
        self.assertEqual(expected_exit_code, exit_code)
        self.assertEqual(FIXTURE_EVENT_COUNT, len(lines))
        for line in lines:
            json.loads(line)


if __name__ == "__main__":
    unittest.main()
