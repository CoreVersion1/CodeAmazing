#include <iostream>
#include <queue>
#include <algorithm>

class BinaryTreeNode {
 public:
  BinaryTreeNode(int x) : val(x), left(nullptr), right(nullptr) {}

 public:
  int val               = {};
  BinaryTreeNode *left  = {};
  BinaryTreeNode *right = {};
};

class TreeNodeWithDepth {
 public:
  TreeNodeWithDepth(BinaryTreeNode *node, int depth) : node(node), depth(depth) {}

 public:
  BinaryTreeNode *node = {};
  int depth            = {};  // 深度信息
};

class Solution {
 public:
  // 前中后序遍历
  void DFS(BinaryTreeNode *root, const std::string &order)
  {
    if (root == nullptr)
    {
      return;
    }

    // 前序遍历
    if (order == "pre")
    {
      std::cout << root->val << " ";
    }

    DFS(root->left, order);

    // 中序遍历
    if (order == "mid")
    {
      std::cout << root->val << " ";
    }

    DFS(root->right, order);

    // 后序遍历
    if (order == "post")
    {
      std::cout << root->val << " ";
    }

    return;
  }

  // 层序遍历，写法1
  // 最简单，但是没有深度信息，所以用的少
  void BFS1(BinaryTreeNode *root)
  {
    if (root == nullptr)
    {
      return;
    }

    std::queue<BinaryTreeNode *> q{};
    q.push(root);

    while (!q.empty())
    {
      auto cur = q.front();
      q.pop();

      std::cout << cur->val << std::endl;

      if (cur->left != nullptr)
      {
        q.push(cur->left);
      }
      if (cur->right != nullptr)
      {
        q.push(cur->right);
      }
    }
  }

  // 层序遍历，写法2
  // 提供每个节点的深度信息，可以解决诸如二叉树最小深度之类的问题，是最常用的层序遍历
  void BFS2(BinaryTreeNode *root)
  {
    if (root == nullptr)
    {
      return;
    }

    std::queue<BinaryTreeNode *> q{};
    q.push(root);
    int depth = 1;  // 深度信息，根节点的深度视为1

    while (!q.empty())
    {
      depth++;

      for (auto cnt = q.size(); cnt > 0; --cnt)
      {
        auto cur = q.front();
        q.pop();

        std::cout << cur->val << " ";

        if (cur->left != nullptr)
        {
          q.push(cur->left);
        }
        if (cur->right != nullptr)
        {
          q.push(cur->right);
        }
      }
    }
  }

  // 层序遍历，写法3
  // 带权重的节点，可用于图结构算法
  void BFS3(BinaryTreeNode *root)
  {
    if (root == nullptr)
    {
      return;
    }

    std::queue<TreeNodeWithDepth> q{};
    q.push({root, 1});  // 根节点的路径权重和是1

    while (!q.empty())
    {
      auto cur = q.front();
      q.pop();

      std::cout << "depth = " << cur.depth << ", val = " << cur.node->val << std::endl;

      if (cur.node->left != nullptr)
      {
        q.push({cur.node->left, cur.depth + 1});
      }
      if (cur.node->right != nullptr)
      {
        q.push({cur.node->right, cur.depth + 1});
      }
    }
  }

 private:
  BinaryTreeNode *root = {};
};

int main(void)
{
  return 0;
}
