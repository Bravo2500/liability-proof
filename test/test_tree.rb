require 'helper'

class TestTree < Minitest::Test

  def test_leaf_node
    node = LiabilityProof::Tree::LeafNode.new({
      'user' => 'jan',
      'balance' => '12.13'
    })

    assert_equal 'jan', node.user
    assert_equal BigDecimal.new('12.13'), node.value
    assert_equal 32, node.nonce.size
    assert_equal 32, Base64.decode64(node.hash).size
  end

  def test_interior_node
    left = LiabilityProof::Tree::LeafNode.new({
      'user' => 'jan',
      'balance' => '12.13'
    })
    right = LiabilityProof::Tree::LeafNode.new({
      'user' => 'zw',
      'balance' => '20.14'
    })

    node  = LiabilityProof::Tree::InteriorNode.new left, right
    assert_equal left,  node.left
    assert_equal right, node.right

    value = (left.value + right.value).to_s('F')
    hash  = LiabilityProof.sha256_base64 "#{value}#{left.hash}#{right.hash}"
    assert_equal hash, node.hash
  end

  def test_tree_generation
    tree = LiabilityProof::Tree.new accounts
    sum = accounts
      .map {|a| BigDecimal.new a['balance'] }
      .inject(0, &:+)

    assert_equal sum, tree.root.value
  end

  def test_tree_generation_with_empty_accounts
    assert_raises ArgumentError do
      LiabilityProof::Tree.new []
    end
  end

  def test_tree_indices
    tree = LiabilityProof::Tree.new accounts
    assert_equal [:left, :left, :left, :left, :left], tree.indices['jan']
    assert_equal [:right, :right], tree.indices['picasso']
  end

  def test_tree_verification_path
    tree = LiabilityProof::Tree.new accounts

    path = tree.verification_path('jan')
    assert_equal 'jan', path.first.user
    assert_equal [:right, :right, :right, :right, :right], path.last.map(&:first)

    path = tree.verification_path('picasso')
    assert_equal 'picasso', path.first.user
    assert_equal [:left, :left], path.last.map(&:first)
  end

end
