package com.example.recipe_sso.backend.model.recipeingredient;

import java.util.Objects;

import com.example.recipe_sso.backend.model.Ingredient;
import com.example.recipe_sso.backend.model.Recipe;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;

@Entity
@Table(name = "recipe_ingredient")
public class RecipeIngredient {

    @EmbeddedId
    private RecipeIngredientId id = new RecipeIngredientId();

    @MapsId("recipeId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipe_id", nullable = false)
    private Recipe recipe;

    @MapsId("ingredientId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ingredient_id", nullable = false)
    private Ingredient ingredient;

    @Column(nullable = false)
    private String amount;

    @Column(nullable = false)
    private String unit;

    public RecipeIngredient() {}

    public RecipeIngredient(Recipe recipe, Ingredient ingredient, String amount, String unit) {
        setRecipe(recipe);
        setIngredient(ingredient);
        this.amount = amount;
        this.unit = unit;
    }

    public RecipeIngredientId getId() { return id; }
    public void setId(RecipeIngredientId id) { this.id = id; }

    public Recipe getRecipe() { return recipe; }
    public void setRecipe(Recipe recipe) {
        this.recipe = Objects.requireNonNull(recipe, "recipe cannot be null");
    }

    public Ingredient getIngredient() { return ingredient; }
    public void setIngredient(Ingredient ingredient) {
        this.ingredient = Objects.requireNonNull(ingredient, "ingredient cannot be null");
    }

    public String getAmount() { return amount; }
    public void setAmount(String amount) { this.amount = amount; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }
}