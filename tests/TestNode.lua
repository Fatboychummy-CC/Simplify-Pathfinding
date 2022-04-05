local Node = require "SimplifyPathfinding.Node"

local suite = cctest.newSuite "TestNode"
  "NODE_CREATE_NO_ERROR" (function()
    EXPECT_NO_THROW(Node.create, 1, 1, 1)
    EXPECT_NO_THROW(Node.create, -1, -1, -1)
    EXPECT_NO_THROW(Node.create, -1, 1, -1)
    EXPECT_NO_THROW(Node.create, -41015, 258478, -1111111)
  end)
  "CREATE_EXPECTATIONS" (function()
    EXPECT_THROW_ANY_ERROR(Node.create, 1, 1, nil)
    EXPECT_THROW_ANY_ERROR(Node.create, 1, nil, 1)
    EXPECT_THROW_ANY_ERROR(Node.create, nil, 1, 1)
  end)
  "CREATE_DATA" (function()
    local x, y, z = 1, 5, 9
    local node = Node.create(x, y, z)

    EXPECT_EQ(node.x, x)
    EXPECT_EQ(node.y, y)
    EXPECT_EQ(node.z, z)

    -- Unknown nodes should be considered blocked, thus any "new" nodes are
    -- created as if they are blocked.
    EXPECT_EQ(node.blocked, true)
  end)
