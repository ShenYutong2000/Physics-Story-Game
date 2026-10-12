window.SCENES = [
  {
    "id": "01",
    "name": "Library Hall",
    "zh": "万象馆大厅",
    "slug": "01-library-hall",
    "bg": "01-library-hall-clean",
    "far": "archive-night-city",
    "mid": "01-library-hall-mid",
    "front": "01-library-hall-front",
    "floor": 778,
    "playerX": 760,
    "story": "日常巡查：检查维护清单与老钟，注意机械仍在运转。",
    "audio": "amb-library",
    "props": [
      {
        "id": "archive-door",
        "x": 52,
        "y": 740,
        "h": 440,
        "tip": "The door to the archive."
      },
      {
        "id": "clock-housing",
        "x": 967,
        "y": 739,
        "h": 372,
        "tip": "The clock is still running. I know how to wind it, but not why it works."
      },
      {
        "id": "maintenance-sheet",
        "x": 1212,
        "y": 575,
        "h": 69,
        "tip": "Evening checks: lamps, pipes, pressure, doors, upper shelves."
      }
    ]
  },
  {
    "id": "02",
    "name": "Machine Room",
    "zh": "机械维护室",
    "slug": "02-machine-room",
    "bg": "02-machine-room-clean",
    "far": "archive-night-city",
    "mid": "02-machine-room-mid",
    "front": "02-machine-room-front",
    "floor": 773,
    "playerX": 870,
    "story": "机械异常：观察仪表，再尝试第二、第四手柄；状态切换演示不代表完整谜题。",
    "audio": "amb-machine",
    "props": [
      {
        "id": "machine-route-diagram",
        "x": 861,
        "y": 431,
        "h": 127,
        "tip": "A service line connects the archive to the castle."
      },
      {
        "id": "gauge-face",
        "x": 1136,
        "y": 342,
        "h": 146,
        "tip": "The pointer is climbing again."
      },
      {
        "id": "status-lamp-states",
        "x": 1046,
        "y": 227,
        "h": 34,
        "cycle": true
      },
      {
        "id": "status-lamp-states",
        "x": 1192,
        "y": 227,
        "h": 34,
        "cycle": true
      },
      {
        "id": "lever-states",
        "x": 1007,
        "y": 421,
        "h": 67,
        "cycle": true
      },
      {
        "id": "lever-states",
        "x": 1082,
        "y": 421,
        "h": 67,
        "cycle": true
      },
      {
        "id": "lever-states",
        "x": 1157,
        "y": 421,
        "h": 67,
        "cycle": true
      },
      {
        "id": "lever-states",
        "x": 1232,
        "y": 421,
        "h": 67,
        "cycle": true
      },
      {
        "id": "stop-switch-states",
        "x": 1338,
        "y": 567,
        "h": 89,
        "cycle": true
      }
    ]
  },
  {
    "id": "03",
    "name": "Upper Stacks",
    "zh": "顶层书库",
    "slug": "03-upper-stacks",
    "bg": "03-upper-stacks-clean",
    "far": "archive-night-city",
    "mid": "03-upper-stacks-mid",
    "front": "03-upper-stacks-front",
    "floor": 708,
    "playerX": 893,
    "story": "寻找残页：沿书架检查旧匣，打开后发现自己的笔迹。屋顶渗水始终向下落。",
    "audio": "amb-library",
    "props": [
      {
        "id": "rolling-ladder",
        "x": 1198,
        "y": 695,
        "h": 459,
        "tip": "The ladder reaches the top shelf."
      },
      {
        "id": "wooden-case-states",
        "x": 1012,
        "y": 277,
        "h": 86,
        "cycle": true,
        "tip": "That handwriting... is it mine?"
      },
      {
        "id": "leak-bucket",
        "x": 1420,
        "y": 695,
        "h": 62,
        "tip": "Water falls from the roof seam into the bucket."
      }
    ]
  },
  {
    "id": "04",
    "name": "Kath’s Room",
    "zh": "Kath 的房间",
    "slug": "04-kath-room",
    "bg": "04-kath-room-clean",
    "far": "archive-dawn-city",
    "mid": "04-kath-room-mid",
    "front": "04-kath-room-front",
    "floor": 801,
    "playerX": 895,
    "story": "准备出发：收好笔记和背包，带着尚未解开的疑问离开。",
    "audio": "amb-room",
    "props": [
      {
        "id": "satchel-states",
        "x": 646,
        "y": 622,
        "h": 110,
        "cycle": true,
        "tip": "A notebook, a pencil, and enough room for questions."
      },
      {
        "id": "hanging-coat",
        "x": 881,
        "y": 478,
        "h": 174,
        "tip": "My coat is still warm from the pipes."
      },
      {
        "id": "notebook-world",
        "x": 1028,
        "y": 538,
        "h": 51,
        "tip": "I should write down what I actually see."
      },
      {
        "id": "desk-lamp-states",
        "x": 1281,
        "y": 536,
        "h": 155,
        "cycle": true
      }
    ]
  },
  {
    "id": "05",
    "name": "Service Road",
    "zh": "通往城堡的维修路",
    "slug": "05-service-road",
    "bg": "05-service-road-clean-v2",
    "far": "05-service-road-far",
    "mid": "05-service-road-mid",
    "front": "05-service-road-front",
    "floor": 824,
    "playerX": 880,
    "story": "章节衔接：远处固定塔楼保持直立，旋转翼倒悬在支承环中；地面重力不变。",
    "audio": "amb-road",
    "props": [
      {
        "id": "service-road-sign",
        "x": 482,
        "y": 775,
        "h": 159,
        "tip": "Castle service entrance →"
      },
      {
        "id": "service-gate-states",
        "x": 1322,
        "y": 891,
        "h": 142,
        "cycle": true,
        "tip": "The service gate still opens."
      }
    ]
  }
];
