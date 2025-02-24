#include <iostream>
#include <vector>

// 单链表节点
class ListNode {
 public:
  ListNode(int x) : val(x), next(nullptr) {}

 public:
  int val        = {};
  ListNode* next = {};
};

class solution {
 public:
  // 数组创建链表
  ListNode* CreateList(const std::vector<int>& arr)
  {
    if (arr.empty())
    {
      return nullptr;
    }

    auto* head = new ListNode(arr[0]);
    auto* cur  = head;

    for (int i = 1; i < arr.size(); ++i)
    {
      cur->next = new ListNode(arr[i]);
      cur       = cur->next;
    }
    return head;
  }

  // 遍历链表
  void TraverseList(ListNode* head)
  {
    for (auto cur = head; cur != nullptr; cur = cur->next)
    {
      std::cout << cur->val << " ";
    }
    std::cout << std::endl;
  }

  // 头部添加节点
  ListNode* AddHead(ListNode* head, int val)
  {
    auto* new_node = new ListNode(val);
    new_node->next = head;
    head           = new_node;
    return head;
  }

  // 尾部添加节点
  ListNode* AddTail(ListNode* head, int val)
  {
    // 找到前驱节点
    auto* cur = head;
    while (cur->next != nullptr)
    {
      cur = cur->next;
    }

    auto* new_node = new ListNode(val);
    cur->next      = new_node;
    return head;
  }

  // 中间插入节点
  ListNode* AddMid(ListNode* head, int val, int pos)
  {
    // 找到前驱节点
    auto* cur = head;
    for (int i = 0; i < pos - 1; ++i)
    {
      if (cur->next != nullptr)
      {
        cur = cur->next;
      }
    }

    auto* new_node = new ListNode(val);
    new_node->next = cur->next;
    cur->next      = new_node;
    return head;
  }

  // 删除节点
  ListNode* DelNode_Index(ListNode* head, int idx)
  {
    if (head == nullptr)
    {
      return head;
    }

    // 找到前驱节点
    auto* cur = head;
    for (int i = 0; i < idx - 1; i++)
    {
      if (cur->next != nullptr)
      {
        cur = cur->next;
      }
    }

    cur->next = cur->next->next;
    return head;
  }

  // 删除头部节点
  ListNode* DelHead(ListNode* head)
  {
    if (head == nullptr)
    {
      return head;
    }

    auto* new_head = head->next;
    delete head;
    return new_head;
  }

  // 删除尾部节点
  ListNode* DelTail(ListNode* head)
  {
    if (head == nullptr)
    {
      return head;
    }

    auto* cur = head;
    while (cur->next->next != nullptr)
    {
      cur = cur->next;
    }

    cur->next = nullptr;
    return head;
  }

  typedef bool (*match_fn)(const ListNode*);
  // 删除所有满足条件的节点
  // 优化版，参考链接：https://coolshell.cn/articles/8990.html
  ListNode* RemoveIf(ListNode* head, match_fn match)
  {
    ListNode** curr = &head;  // 二级指针，方便处理头节点

    while (*curr != nullptr)
    {
      ListNode* entry = *curr;

      if (match(entry))
      {
        *curr = entry->next;  // 删除当前节点
        delete entry;
      }
      else
      {
        curr = &entry->next;  // 继续向后遍历
      }
    }

    return head;
  }
};

int main(void)
{
  std::cout << "CreateList: " << std::endl;
  std::vector<int> nums = {1, 2, 3, 4, 5};
  auto* head            = solution().CreateList(nums);
  solution().TraverseList(head);

  std::cout << "AddHead: " << std::endl;
  head = solution().AddHead(head, 0);
  solution().TraverseList(head);

  std::cout << "AddTail: " << std::endl;
  head = solution().AddTail(head, 6);
  solution().TraverseList(head);

  std::cout << "AddMid: " << std::endl;
  head = solution().AddMid(head, 7, 3);
  solution().TraverseList(head);

  std::cout << "DelNode: " << std::endl;
  head = solution().DelNode_Index(head, 3);
  solution().TraverseList(head);

  std::cout << "DelHead: " << std::endl;
  head = solution().DelHead(head);
  solution().TraverseList(head);

  std::cout << "DelTail: " << std::endl;
  head = solution().DelTail(head);
  solution().TraverseList(head);

  std::cout << "RemoveIf: " << std::endl;
  head = solution().RemoveIf(head, [](const ListNode* node) { return node->val % 2 == 0; });
  solution().TraverseList(head);

  return 0;
}
