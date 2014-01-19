Feature: Running manage layer functions
  As AnaDraw developer
  I want to have a manager layer feature file
  So I can begin testing by create delete copy move layer

  Background:
    Given I start to edit a new file in the Paint Screen
    And I should see a "Layer" button
    When I touch the "Layer" button
    Then I wait to see "LayerManager"
    
  Scenario: Painting create new layer above selected layer
    Given I touch layer number 1
    And I should see a "AddLayer" button
    When I touch the "AddLayer" button
    Then I should create a new layer above
  @focus    
  Scenario Outline: Painting delete selected layer
    Given I should see layer number <num>
    When I touch Delete for layer number <num>
    Then I should delete layer number <num>
    Examples:
    | num |
    | 2   |
    
  Scenario: Painting copy selected layer
    Given this is pending

  Scenario: Painting move layer up
    Given this is pending
    
  Scenario: Painting move layer down
    Given this is pending
              
  Scenario: Painting merge down selected layer
    Given this is pending
      
  Scenario: Painting edit background color
    Given this is pending
    
  Scenario: Painting clear selected layer content
    Given this is pending    
